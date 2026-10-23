FROM golang:1.22-alpine AS build
WORKDIR /src
COPY main.go .
RUN go mod init hello && CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /hello .

# Chainguard base: minimal, no shell, runs non-root (approved-base policy)
FROM cgr.dev/chainguard/static:latest
COPY --from=build /hello /hello
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/hello"]
