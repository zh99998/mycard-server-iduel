#encoding: UTF-8
require_relative 'game'
require_relative 'game_event'
require_relative 'user'
require_relative 'room'
require_relative 'iduel/game'
class Iduel
  def connect
    require 'socket'
    require 'open-uri'
    @conn = TCPSocket.new(Server, Port)
    @conn.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace
    @users = {}
  end
  def server(username, password)
    login username, password
    lasterror = Time.at 0
    while @conn
      recv @conn.gets(RS)
      case event = Game_Event.poll
      when Game_Event::PrivateChat #忽略其他消息
        $log.info('收到指令'){event.inspect}
        @users[event.user] ||= :hall
        head, content = event.content.split(" ", 2)
        result = handle_server(event.user, head, content)
        $game.chat "#{head} #{result}", event.user unless result.nil?
      when Game_Event::Error
        if event.fatal
          sleep 60*5 if Time.now - lasterror < 60
          lasterror = Time.now
          login username, password 
        end
      end
    end
  end
  def handle_server(user, head, content=nil)
    case head
    when "users"
      @users.collect{|user, room_id|[user.id, room_id]}.join(",")
    when "join"
      room_id = content.to_i
      return unless room_id != 0
      @users[user] = room_id
      ""
    when "chat"
      return unless content
      room_id, content = content.split(",", 2)
      room_id = room_id.to_i
      return unless room_id != 0 and content
      users = []
      @users.each{|user, user_room_id|users << user if user_room_id == room_id}
      users.collect{|user, user_room_id|user.id}.join(",")
    else
      nil
    end
  end
end



#读取命令行参数
log = "log.log"
ARGV.each do |arg|
  case arg
  when /--log=(.*)/
    log.replace $1
  end
end

#设置标准输出编码（windows)
STDOUT.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]

require 'logger'
if log == "STDOUT" #调试用
  log = STDOUT
end
$log = Logger.new(log)
$log.info("main"){"初始化成功"}

$game = Iduel.new
$game.server('zh99997', '111111')

