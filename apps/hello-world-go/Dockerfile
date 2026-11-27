# The Go standard library is compiled INTO the binary, so the toolchain version decides which stdlib CVEs ship.
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /hello .

# Chainguard base: minimal, no shell, runs non-root (approved-base policy)
# Pinned by digest (Chainguard's free tier only publishes :latest); refresh the digest deliberately
FROM cgr.dev/chainguard/static@sha256:599c3cd7597b84aa149c4282beecc8c6d4e1cb5c95dc8d982e70cd0a2a9147a2
COPY --from=build /hello /hello
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/hello"]
