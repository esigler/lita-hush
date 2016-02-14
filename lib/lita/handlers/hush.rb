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
        /^room\sadd\s(?<user>.*)$/,
        :add,
        command: true,
        help: {
          t('help.add.syntax') => t('help.add.desc')
        }
      )

      route(
        /^room\smoderation\son$/,
        :moderate,
        command: true,
        help: {
          t('help.moderate.syntax') => t('help.moderate.desc')
        }
      )

      route(
        /^room\sremove\s(?<user>.*)$/,
        :remove,
        command: true,
        help: {
          t('help.remove.syntax') => t('help.remove.desc')
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

      route(
        /room\smoderation\soff/,
        :unmoderate,
        command: true,
        help: {
          t('help.unmoderate.syntax') => t('help.unmoderate.desc')
        }
      )

      # rubocop:disable AbcSize
      def add(response)
        src = response.message.source
        return if src.room.nil?
        room_id = src.room
        room_name = src.room_object.name
        user = Lita::User.fuzzy_find(response.match_data['user'])
        return response.reply(t('error.nouser')) if user.nil?
        give_voice(room_id, user)

        response.reply(t('add.complete', user: user.name, room: room_name))
      end
      # rubocop:enable AbcSize

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
        moderate_room(src.room)
        give_voice(src.room, src.user)
        response.reply(t('moderate.complete'))
      end

      # rubocop:disable AbcSize
      def remove(response)
        src = response.message.source
        return if src.room.nil?
        room_id = src.room
        room_name = src.room_object.name
        user = Lita::User.fuzzy_find(response.match_data['user'])
        return response.reply(t('error.nouser')) if user.nil?
        take_voice(room_id, user)

        response.reply(t('remove.complete', user: user.name, room: room_name))
      end
      # rubocop:enable AbcSize

      def status(response)
        msg = if room_moderated?(response.message.source.room)
                t('status.moderated')
              else
                t('status.unmoderated')
              end

        response.reply(msg)
      end

      def unmoderate(response)
        unmoderate_room(response.message.source.room)
        response.reply(t('unmoderate.complete'))
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

      def unmoderate_room(room)
        return if room.nil?
        redis.srem('moderated_rooms', room)
      end

      def user_has_voice?(room, user)
        return false if room.nil? || user.nil?
        redis.sismember("voice_list_#{room}", user.id.to_s)
      end

      Lita.register_handler(self)
    end
  end
end
