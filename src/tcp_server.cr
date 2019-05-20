require "socket"

module TcpServer
  VERSION = "0.1.0"

  N = 10_u8
  R = 13_u8

  server = TCPServer.new(80)
  while server.accept?.try { |client| spawn {
    buffer, buffer_size, header = Bytes.new(1 << 10 * 2), 0, Bytes.new(0)
    method, path, http_version, headers = "GET", "", "", Hash(String, String).new

    buffer_size = client.read(buffer)
    buffer_size.times { |i|
      if i > 4 && buffer[i - 3] == R && buffer[i - 2] == N && buffer[i - 1] == R && buffer[i] == N
        break header = Bytes.new(i - 3) { |j| buffer[j] }
      end
    }

    String.new(header).split("\r\n").each_with_index { |line, i|
      puts line
      if i == 0
        method, path, http_version = line.split(" ")
        next
      end
      key, value = line.split(": ", 2)
      headers[key] = value
    }
    puts "=== header over ===\n\n"

    if method == "POST"
      body_size = headers["Content-Length"].to_i
      buffer_body_size = buffer_size - header.size - 4
      puts String.new(Bytes.new(buffer_body_size) { |i| buffer[i + header.size + 4] })
      if buffer_size < header.size + body_size + 4
        loop {
          buffer_size = client.read(buffer)
          puts String.new(Bytes.new(buffer_size) { |i| buffer[i] })

          buffer_body_size += buffer_size
          break if buffer_body_size >= body_size
        }
      end

      puts "=== body over ===\n\n"
    end 

    res = [ "HTTP/1.1 200 OK" ]
    res << "Content-Type: text/html; charset=utf-8"
    res << "Set-Cookie: yyy_id=d09648354e040982033941b536a7841a21558335493; path=/; domain=xxx.com; HttpOnly"
    res << "Set-Cookie: xxx_id=235ff92fd48a2024e84ab67da63e83ca; path=/; HttpOnly"
    res << ""
    res << "<input name=\"formcheck\" value=\"de35c20d6d39701ec44a64dc3c3132d9\" />"

    client.write res.join("\r\n").to_slice

    client.close
  } }; end
end
