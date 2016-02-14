module Lita
  module Handlers
    class Hush < Handler
      # NOTE: I don't like using catchall matchers.  Is there a cleaner way?
      route(
        /.*/,
        :ambient,
        command: false
      )

      route(
        /^room\s(add|remove)\s(?<user>.*)$/,
        :voice,
        command: true,
        help: {
          t('help.voice.syntax') => t('help.voice.desc')
        }
      )

      route(
        /^room\smoderation\s(?<toggle>(on|off))$/,
        :moderate,
        command: true,
        help: {
          t('help.moderate.syntax') => t('help.moderate.desc')
        }
      )

      route(
        /^room\sstatus$/,
        :status,
        command: true,
        help: {
          t('help.status.syntax') => t('help.status.desc')
        }
      )

      def ambient(response)
        src = response.message.source
        return unless room_moderated?(src.room)
        return if user_has_voice?(src.room, src.user)
        return if response.message.body == 'room status'

        response.reply_privately(t('ambient.pm', room: src.room_object.name))
        # NOTE: This is the nuclear option, I'd like to give a ramp up at least?
        # response.reply("/kick #{robot.mention_format(src.user)}")
      end

      def moderate(response)
        src = response.message.source

        action = if response.match_data['toggle'] == 'on'
                   moderate_room(src.room)
                   give_voice(src.room, src.user)
                   'moderated'
                 else
                   unmoderate_room(src.room)
                   'unmoderated'
                 end

        response.reply(t('moderation.complete', action: action))
      end

      def status(response)
        src = response.message.source
        state = room_moderated?(src.room) ? 'moderated' : 'unmoderated'

        response.reply(t('status.overview', state: state))
      end

      def voice(response)
        src = response.message.source
        user = Lita::User.fuzzy_find(response.match_data['user'])
        return response.reply(t('error.nouser')) unless user

        action = toggle_voice(src.room, user) ? 'added to' : 'removed from'

        response.reply(t('voice.complete',
                         user: user.name,
                         room: src.room_object.name,
                         action: action))
      end

      private

      def give_voice(room, user)
        return if room.nil? || user.nil?
        redis.sadd("voice_list_#{room}", user.id)
      end

      def moderate_room(room)
        return if room.nil?
        redis.sadd('moderated_rooms', room)
      end

      def room_moderated?(room)
        return false if room.nil?
        redis.sismember('moderated_rooms', room)
      end

      def take_voice(room, user)
        return if room.nil? || user.nil?
        redis.srem("voice_list_#{room}", user.id)
      end

      def toggle_voice(room, user)
        if user_has_voice?(room, user)
          take_voice(room, user)
          false
        else
          give_voice(room, user)
          true
        end
      end

      def unmoderate_room(room)
        return if room.nil?
        redis.srem('moderated_rooms', room)
      end

      def user_has_voice?(room, user)
        return false if room.nil? || user.nil?
        redis.sismember("voice_list_#{room}", user.id)
      end

      Lita.register_handler(self)
    end
  end
end
