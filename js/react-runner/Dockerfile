ARG REACH_VERSION
ARG STDLIB_IMAGE=reachsh/stdlib:$REACH_VERSION
ARG JS_DEPS_IMAGE=reachsh/js-deps:$REACH_VERSION

# hadolint ignore=DL3006
FROM $JS_DEPS_IMAGE as js-deps

# hadolint ignore=DL3006
FROM $STDLIB_IMAGE

WORKDIR /app
COPY --from=js-deps /js-deps/node_modules/ /app/node_modules/
COPY package.json \
     /app/

# unfortunately we need to npm install here
# because react-scripts requires webpack 4
# but we've got webpack 5 installed
RUN npm install
RUN npm link @reach-sh/stdlib

COPY public/ /app/public/

ENTRYPOINT ["npm", "run", "--"]
CMD ["start"]

ARG REACH_GIT_HASH
ENV REACH_GIT_HASH="${REACH_GIT_HASH}"
