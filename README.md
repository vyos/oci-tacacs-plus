# oci-tacacs-plus
OCI used during smoketest to act as TACACS+ server

## Images

| Tag | Contents |
|---|---|
| `alpine` | tac_plus + Perl with LDAP/SSL modules for Mavis (~56 MB) |
| `alpine-slim` | tac_plus + spawnd only, no Perl (~11 MB) |

## Building

```
docker build --target slim -t tac_plus:alpine-slim .
docker build -t tac_plus:alpine .
```

Multi-arch (amd64 + arm64, needs buildx and qemu binfmt or native arm64 nodes):

```
docker buildx build --platform linux/amd64,linux/arm64 --target slim \
    -t <registry>/tacacs_plus:alpine-slim --push .
```

## Configuration

Mount a configuration directory at `/etc/tac_plus` (it must contain
`tac_plus.cfg`).

It exposes port 49.
