FROM restic/restic:0.9.6 as restic

FROM node:10-alpine

COPY --from=restic /usr/bin/restic /usr/bin/restic

ADD https://downloads.rclone.org/rclone-current-linux-amd64.zip /
RUN unzip rclone-current-linux-amd64.zip && mv rclone-*-linux-amd64/rclone /bin/rclone && chmod +x /bin/rclone

RUN apk add --update --no-cache ca-certificates fuse openssh-client heirloom-mailx fuse

RUN \
    mkdir -p /mnt/restic /var/spool/cron/crontabs /var/log; \
    touch /var/log/cron.log;

ENV RESTIC_REPOSITORY=/mnt/restic
ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""
ENV NFS_TARGET=""
ENV BACKUP_CRON="0 */6 * * *"
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""
ENV MAILX_ARGS=""
ENV BACKUP_VOLUME="/restic-volume"
ENV BACKUP_FOLDER="data"

# ARG USER=postgres
# ARG UID=999
# ARG GID=999
# RUN mkdir -p restic-volume/data/postgres-data
# RUN chown -R $UID restic-volume/data/postgres-data

# ARG SOLR_UID=33007
# RUN mkdir -p /data/solr-data
# RUN chown -R $SOLR_UID /data/solr-data
# USER postgres

VOLUME ${BACKUP_VOLUME}

WORKDIR /usr/src/app

COPY backup.sh /bin/backup
COPY entry.sh .

RUN chmod +x /usr/src/app/entry.sh

COPY server .
COPY handlers handlers

RUN npm install

EXPOSE 3000
ENTRYPOINT ["sh","/usr/src/app/entry.sh"]
# CMD ["tail","-fn0","/var/log/cron.log"]
CMD [ "node", "index.js" ]

