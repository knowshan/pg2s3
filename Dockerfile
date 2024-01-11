FROM alpine:3.19
RUN apk --update add postgresql13-client python3=3.11.6-r1 aws-cli=2.13.25-r0 jq=1.7.1-r0 bash=5.2.21-r0
RUN rm -rf /var/cache/apk/*

WORKDIR /src
COPY src /src
