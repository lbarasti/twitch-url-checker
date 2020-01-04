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
+--------------------------+--------------+--------------+--------------+
| Url                      |      Success | Failure      |       Avg RT |
+--------------------------+--------------+--------------+--------------+
| http://google.com        |            4 | 0            |      10.9152 |
| https://amazon.co.uk     |            4 | 0            |      28.9708 |
| https://crystal-lang.org |            4 | 0            |      50.9932 |
| https://github.com/non-e |            0 | 4*           |          0.0 |
| xisting-project          |              |              |              |
+--------------------------+--------------+--------------+--------------+
```

## Contributors

- [lorenzo.barasti](https://github.com/lbarasti) - creator and maintainer
