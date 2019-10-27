# url-checker

A concurrent, terminal-based tool to check the status of a set of URLs. Written over live-coding sessions at https://www.twitch.tv/lbarasti

## Installation

```
shards install
```

## Usage
```
crystal src/url-checker.cr
```
Sample output:
```
+--------------------------+--------------+--------------+
| Url                      |      Success |      Failure |
+--------------------------+--------------+--------------+
| http://google.com        |            1 |            0 |
| http://localhost:3000    |            0 |            1 |
| http://non-existing-1312 |            0 |            1 |
| .com                     |              |              |
| https://amazon.co.uk     |            1 |            0 |
+--------------------------+--------------+--------------+
```

## Contributors

- [lorenzo.barasti](https://github.com/lbarasti) - creator and maintainer
