# jmplourde.com

This is the repository that contains my personal website and all the required scripts to build it from markdown to html. The scripts behind it comes from the project barf, an extremely minimal blog generator.

The entire build script is less than 100 lines of shell.

(barf is a modified/forked version of Karl Bartel's fantastic [blog.sh](https://github.com/karlb/karl.berlin). Be sure to check it out since my version does things slightly different.)

---

## Requirements

- rsync
- smu (see below)
- entr (optonal)
- standard UNIX tools

---

## Basic Setup

Clone and build this patched version of smu:

```sh
git clone https://git.sr.ht/~bt/smu
cd smu
sudo make install
```

## Write Blog Posts

Create an `.md` file inside `/posts`. The first line should be a markdown h1 title, followed by a blank line followed by the publishing date on a newline. There should be another blank line before the post content.

## Build

After cloning this repo, navigate inside the directory and build:

```sh
make build
```

The blog content will be in the `build` directory.

Media (such as images, videos) are placed in the "public" folder and carried over to the "build" folder via rsync. You can easily remove this altogether inside the main `barf` script if you plan to store media elsewhere (or not use any at all).

### Test locally

Inside the directory run:

```
make watch
cd build && python3 -m http.server 3003
```

