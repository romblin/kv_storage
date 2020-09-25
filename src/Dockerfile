FROM tarantool/tarantool:1.7
MAINTAINER Roman Blinov

COPY *.lua /opt/tarantool/
ADD .rocks /opt/tarantool/.rocks
WORKDIR /opt/tarantool

CMD ["tarantool", "app.lua"]
