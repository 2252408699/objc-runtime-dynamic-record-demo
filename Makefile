CC := xcrun clang
CFLAGS := -fobjc-arc -Wall -Wextra -framework Foundation

.PHONY: run clean

run: dynamic-record-demo
	./dynamic-record-demo

dynamic-record-demo: Sources/main.m
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f dynamic-record-demo
