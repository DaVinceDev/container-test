# Mini-container runtime in Zig

This project is a mini container runtime built from scratch. It teached me how containers work under the hood using linux syscalls like: clone,unshare,
mount,chroot,etc; along with new knowledge about memory management in zig.

## How to test it

This is a step-by-step on how to get the container up and running to test it and see its limitations:

0º If you don't already have it, download docker and make sure it's working by running `docker run hello`

1º Clone the repository `git clone https://github.com/DaVinceDev/container-test`

NOTE: DO NOT! AND I REPEAT DO NOT RUN THIS OUTSIDE THE DOCKER CONTAINER, WHATEVER HAPPENS IT'S YOUR FAULT.

2º Go to the repo directory and create a docker container using the Dockerfile

`cd container-test/`
`docker build -t <container_name> .`

3º Run the container with the necessary permissions, the code will not run if it doesn't

`docker run --cap-add=SYS_ADMIN --cap-add=SYS_CHROOT --cap-add=SYS_PTRACE -it <containername>`

4º Build the executable for the container, running the code directly fails when it comes to fetching for PID's 

`zig build-exe container.zig`

5º Run the executable and pass an argument like `bash`. The best argument for the test anyways lol

`./container bash`

There! You're inside a container.

## Testing

Now that you're inside the container, you might want to test atleast two things:

`Hostname test` 
and 
`Fetch for PID's`

### Hostname test 

Inside the container(assuming you passed bash as argument) type the `hostname` command and it'll echo the container hostname. To change it you just go 
`hostname zig-box` or whatever you want to call it. Then again try `hostname` and it'll echo the name you gave it. Now exit the container and try `hostname`
and it should echo the development container ID.


### Fetch for PID's

Again, assuming you're inside the container (not the dev one) if you try to type `ps` it will fail because it's not installed. But then you might notice you're 
inside a ubuntu container(development one) so it should have ps command. Happens that the rootfs(root filesystem) does not have ps by default in the test 
container. But you can install it with:

`apt-get update` to update the database 
`apt-get procps` to install `ps`

And then you can try again `ps` and should show: the container, bash and ps. And you now it's working if the TTY's are unknow.


## How does it work?

You can check the code and the notes to see and understand the process behind it. 


## CREDITS 

This code is an adaptation in zig of this video:

**Containers from scratch in Go**: https://youtu.be/Utf-A4rODH8?si=jzC6Zg0cWRUceNRD

This **Liz Rice** did an amazing job at simplifying the process of creation of a container and it would be my bad if I didn't mention her and the reference of 
this project
