FROM cloudnativek8s/microservices-java17-alpine-u10k:v1.0.28 

USER root
RUN apk update && apk add python3
RUN mkdir -p /usr/lib/trino && chown -R user:app /usr/lib/trino
USER user 
COPY --chown=user:app docker-build/trino /usr/lib/trino

CMD [ "/usr/lib/trino/bin/run-trino" ]



