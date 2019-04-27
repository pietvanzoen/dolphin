# Install elixir deps
FROM elixir AS deps
WORKDIR app
ENV MIX_ENV=prod
ARG SECRET_KEY_BASE
COPY . .
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get

# Install/build javascript deps
FROM node:lts AS static
COPY --from=deps app .
WORKDIR assets
RUN npm install
RUN npm run deploy

# Compile
FROM elixir
ENV MIX_ENV=prod
ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
COPY --from=deps app .
COPY --from=static priv/static priv/static
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix phx.digest

CMD ["mix", "phx.server"]
