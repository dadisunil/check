# The Go standard library is compiled INTO the binary, so the toolchain version decides which stdlib CVEs ship.
FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /hello .

# Chainguard base: minimal, no shell, runs non-root (approved-base policy)
# Pinned by digest (Chainguard's free tier only publishes :latest); refresh the digest deliberately
FROM cgr.dev/chainguard/static@sha256:8658e9eaeb2294fa0e49b0667f7d66b4e21fa7690b8d2a4c30cd1d013ceb9eb7
COPY --from=build /hello /hello
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/hello"]
