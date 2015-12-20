# `beep` for OS X

> Because Apple decided retina screens are more valuable than hardware speakers (_scoff_)

```shell
$ beep # plays a 750Hz beep for 1s
$ beep -f 1000 -l 500 # plays a 1000Hz beep for 500ms
```

## Usage

```
usage: beep [-f N] [-l N]

Plays an audible sine wave

-h, --help                 shows this message
-f, --frequency=N          beep at N Hz
-l, --length=N             beep for N milliseconds
```

# Building
Must have [XOpt](https://github.com/Qix-/xopt) built and in your `CFLAGS`
environment variable as header/library include paths (or installed via a package
manager if I ever get around to it...)

Then just call `make`.

Example:

```shell
$ CFLAGS="-I /src/xopt -L /src/xopt" make
```

# License
Slightly adapted from an answer by [admsyn](http://stackoverflow.com/a/14478420).
Adaptation by Josh Junon.

Released under the [MIT License](LICENSE).
