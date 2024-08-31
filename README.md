# Howto

CLI tool for finding coding answers instantly by scraping from StackOverflow.

### Installation

**Building from source**

Please use Swift version 5.6 or newer.

```bash
git clone https://github.com/ilaumjd/howto.git
cd howto
swift build -c release
```

The executable will be created in the `.build/release/` directory.

- Other installation method is coming soon

### Usage

```
howto -h
```

#### Arguments and Options

```
ARGUMENTS:
  <query>                 Coding question you want to ask

OPTIONS:
  -e, --engine <engine>   Search engine to use (google, bing) (default: google)
  -n, --num <num>         Number of answers to return (default: 1)
  -l, --link              Show source link of the answer
  -b, --bat               Pipe output to bat for syntax highlighting
  --version               Show the version.
  -h, --help              Show help information.
```

### Syntax Highlighting

You can use `bat` for syntax highlighting, please refer the installation guide on their GitHub repository (https://github.com/sharkdp/bat).

### TODOs

- [x] Basic search feature
- [x] Select search engine
- [x] `bat` syntax highlighting
- [ ] Configuration file
- [ ] Answer caching
- [ ] Make a separate library
- [ ] Get answer from another sources

### Notes

This project is heavily inspired by [howdoi](https://github.com/gleitz/howdoi).
