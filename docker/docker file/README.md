# Dockerfile Instruction Reference

Every Dockerfile instruction, shown with its common option variants. Built around a working multi-stage Node.js example — the active lines form a real, buildable Dockerfile; alternate forms are shown as comments/tables alongside.

---

## Table of Contents

1. [syntax directive](#syntax-directive)
2. [ARG](#arg)
3. [FROM](#from)
4. [LABEL](#label)
5. [WORKDIR](#workdir)
6. [ENV](#env)
7. [COPY](#copy)
8. [ADD](#add)
9. [RUN](#run)
10. [USER](#user)
11. [EXPOSE](#expose)
12. [VOLUME](#volume)
13. [HEALTHCHECK](#healthcheck)
14. [STOPSIGNAL](#stopsignal)
15. [SHELL](#shell)
16. [ENTRYPOINT & CMD](#entrypoint--cmd)
17. [ONBUILD](#onbuild)
18. [Full example (multi-stage build)](#full-example)

---

## syntax directive

Optional, first line of the file — opts into the newest BuildKit Dockerfile frontend features (cache/secret mounts, etc.).

```dockerfile
# syntax=docker/dockerfile:1
```

---

## ARG

Build-time-only variable. Not present in the final image or running container.

```dockerfile
ARG NODE_VERSION=20
ARG BUILD_ENV=production
```

| Note | Detail |
|---|---|
| Scope | An `ARG` declared before `FROM` is only usable in `FROM` itself — re-declare it after `FROM` to use it inside that stage. |
| `--build-arg` | Override at build time: `docker build --build-arg NODE_VERSION=18 .` |

---

## FROM

Sets the base image. Starts a new build stage.

```dockerfile
FROM node:${NODE_VERSION}-alpine AS build
```

```dockerfile
# Other forms:
FROM ubuntu:22.04                                  # by tag
FROM ubuntu@sha256:abc123...                       # by digest (immutable, reproducible)
FROM --platform=linux/amd64 node:20-alpine         # force platform (multi-arch builds)
FROM scratch                                        # empty base, for fully static binaries
```

---

## LABEL

Attaches metadata to the image. Multiple labels can be combined into one instruction (fewer layers).

```dockerfile
LABEL maintainer="team@example.com"
LABEL version="1.0" \
      description="Example multi-stage Dockerfile" \
      org.opencontainers.image.source="https://github.com/example/repo"
```

---

## WORKDIR

Sets (and creates, if missing) the working directory for subsequent instructions.

```dockerfile
WORKDIR /app
```

---

## ENV

Sets environment variables that **persist into the running container** (unlike `ARG`).

```dockerfile
ENV NODE_ENV=${BUILD_ENV} \
    PORT=3000 \
    npm_config_loglevel=warn
```

```dockerfile
# Legacy single key-value form:
ENV NODE_ENV production
```

---

## COPY

Copies files from the build context, or from another build stage / external image.

```dockerfile
COPY package.json package-lock.json ./
```

| Option | Purpose |
|---|---|
| `--chown=user:group` | Set file ownership on copy |
| `--from=<stage-name>` | Copy from a named stage (multi-stage builds) |
| `--from=<image>` | Copy from an external image, e.g. `--from=nginx:1.27` |
| JSON array form | `COPY ["src with spaces/", "./dest/"]` — required for paths containing spaces |

```dockerfile
COPY --chown=node:node . .
COPY --from=build /app/dist ./dist
COPY --from=nginx:1.27 /etc/nginx/nginx.conf /tmp/
```

---

## ADD

Like `COPY`, but also supports fetching remote URLs and auto-extracting local tar archives.

```dockerfile
ADD https://example.com/file.tar.gz /tmp/    # fetch a remote file
ADD archive.tar.gz /app/                      # auto-extracted into /app
```

> Prefer `COPY` over `ADD` unless you specifically need URL fetching or auto-extraction — `ADD`'s implicit behavior is a common source of confusing builds.

---

## RUN

Executes a command at build time, creating a new image layer.

```dockerfile
RUN npm ci --only=production
```

| Form | Example | Notes |
|---|---|---|
| Shell form | `RUN npm ci --only=production` | Runs via `/bin/sh -c`; supports variable expansion, `&&`, pipes |
| Exec form | `RUN ["npm", "ci", "--only=production"]` | No shell, no variable expansion, no shell features |
| Combined + cleanup | `RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*` | Keeps image layers small by cleaning up in the same `RUN` |
| BuildKit cache mount | `RUN --mount=type=cache,target=/root/.npm npm install` | Speeds up rebuilds by persisting a cache directory across builds |
| BuildKit secret mount | `RUN --mount=type=secret,id=npmrc npm install` | Uses a secret at build time without baking it into image layers |

---

## USER

Sets the user (and optionally group) that subsequent instructions and the container process run as.

```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

```dockerfile
# Numeric form also valid:
USER 1000:1000
```

> Running as a non-root user is a security best practice — avoid leaving the default `root` user in production images.

---

## EXPOSE

Documents which port(s) the container listens on. **Does not actually publish the port** — that's done with `docker run -p`.

```dockerfile
EXPOSE 3000
```

```dockerfile
EXPOSE 3000/tcp
EXPOSE 53/udp
```

---

## VOLUME

Declares a mount point intended for persistent or externally-managed data.

```dockerfile
VOLUME ["/app/data"]
```

```dockerfile
# Shell form, multiple paths:
VOLUME /app/data /app/logs
```

---

## HEALTHCHECK

Defines how Docker checks whether the container is still healthy.

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1
```

| Option | Meaning |
|---|---|
| `--interval` | Time between checks (default 30s) |
| `--timeout` | Time before a check counts as failed (default 30s) |
| `--start-period` | Grace period before failures count, for slow-starting apps |
| `--retries` | Consecutive failures before marking `unhealthy` |
| `HEALTHCHECK NONE` | Disables a healthcheck inherited from the base image |

---

## STOPSIGNAL

Sets the signal sent to the container's main process on `docker stop`.

```dockerfile
STOPSIGNAL SIGTERM
```

```dockerfile
STOPSIGNAL SIGQUIT
```

---

## SHELL

Overrides the default shell (`/bin/sh -c` on Linux) used for shell-form instructions.

```dockerfile
SHELL ["/bin/bash", "-c"]
```

```dockerfile
# Windows containers:
SHELL ["powershell", "-command"]
```

---

## ENTRYPOINT & CMD

Define what actually runs when the container starts. They combine: `CMD` supplies default arguments to `ENTRYPOINT`, and `CMD`'s arguments (only) can be overridden at `docker run <image> other-args`.

```dockerfile
ENTRYPOINT ["node"]
CMD ["dist/server.js"]
```

Result: `node dist/server.js` by default; `docker run myimage dist/other.js` runs `node dist/other.js` instead.

| Pattern | Example | Behavior |
|---|---|---|
| Exec form (preferred) | `ENTRYPOINT ["node"]` | No shell wrapper — signals (e.g. SIGTERM) go directly to the process (PID 1) |
| Shell form | `ENTRYPOINT node dist/server.js` | Runs via `/bin/sh -c` — the shell becomes PID 1, which can swallow signals |
| CMD alone (no ENTRYPOINT) | `CMD ["node", "dist/server.js"]` | Fully replaced by any args passed to `docker run` |
| CMD shell form | `CMD node dist/server.js` | Same shell-wrapping caveat as above |

---

## ONBUILD

Registers an instruction that triggers **only when this image is used as a base image** for another build. Mainly used in base/template images.

```dockerfile
ONBUILD COPY . /app/src
ONBUILD RUN npm install
```

---

## Full Example

A complete, working multi-stage Dockerfile combining the instructions above:

```dockerfile
# syntax=docker/dockerfile:1

ARG NODE_VERSION=20
ARG BUILD_ENV=production

# ---- Build stage ----
FROM node:${NODE_VERSION}-alpine AS build
LABEL maintainer="team@example.com"
WORKDIR /app
ARG BUILD_ENV
ENV NODE_ENV=${BUILD_ENV} \
    PORT=3000

COPY package.json package-lock.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# ---- Runtime stage ----
FROM node:${NODE_VERSION}-alpine AS runtime
ENV NODE_ENV=production \
    PORT=3000
WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/package.json ./

USER appuser

EXPOSE 3000
VOLUME ["/app/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

STOPSIGNAL SIGTERM

ENTRYPOINT ["node"]
CMD ["dist/server.js"]
```

## Quick Option Reference

| Instruction | Key options |
|---|---|
| `FROM` | `--platform=<os/arch>`, `AS <stage-name>`, `image:tag` or `@sha256:digest` |
| `COPY` / `ADD` | `--from=<stage\|image>`, `--chown=<user:group>`, `--chmod=<mode>` |
| `RUN` | shell form vs. exec form (`["cmd","arg"]`); `--mount=type=cache\|secret\|bind` (BuildKit only) |
| `ENTRYPOINT` / `CMD` | shell form vs. exec form; `CMD` provides default args to `ENTRYPOINT` |
| `HEALTHCHECK` | `--interval`, `--timeout`, `--start-period`, `--retries`, or `NONE` |
| `USER` | `name`, `name:group`, `uid`, `uid:gid` |
| `EXPOSE` | `port`, `port/tcp`, `port/udp` — documentation only, use `-p` to actually publish |
| `VOLUME` | JSON array form or shell form, one or more paths |
