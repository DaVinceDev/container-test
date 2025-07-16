# Notes

# RUN LIKE SUPERUSER
docker run --cap-add=SYS_ADMIN --cap-add=SYS_CHROOT --cap-add=SYS_PTRACE -it zig-sandbox:latest
