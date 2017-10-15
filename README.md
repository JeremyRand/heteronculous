# Heteronculous: A Proxy Leak Detector That (Hopefully) Sucks Slightly Less

*For when Phidelius and Mimblewimble just won't save you from Rattus Animagus.*

Heteronculous is a script that can check your code for proxy leaks.  Heteronculous can use the existing automated tests that your project runs in CI, or it can be run with manual tests.  Heteronculous doesn't require root privileges (or any interesting privileges as far as I know), nor does it require unusual kernel features like tcpdump can.

## Usage

Usage of Heteronculous is fairly straightforward.

Let's say that you normally run your tests like this:

~~~
./run_tests.sh
~~~

And let's say that your tests are expected to go through a proxy at `127.0.0.1` on port `9050`.  You can check for leaks like this:

~~~
export LEAK_CI_ALLOW_IP_PROTOCOL=1
export LEAK_CI_ALLOW_IP4_ADDR_PORT="127.0.0.1
9050"
export LEAK_CI_ALLOW_IP6_ADDR_PORT=""

./detect_leaks.sh ./run_tests.sh
~~~

`./detect_leaks.sh` will return an exit code of `1` if it finds any leaks (and `0` otherwise); it will also display an `strace` log of the leaks it found.

Let's say that you're using multiple proxies in parallel (perhaps because Tor automatically stream-isolates different proxy ports).  You can do that like this:

~~~
export LEAK_CI_ALLOW_IP_PROTOCOL=1
export LEAK_CI_ALLOW_IP4_ADDR_PORT="127.0.0.1
9050
127.0.0.1
9150"
export LEAK_CI_ALLOW_IP6_ADDR_PORT=""

./detect_leaks.sh ./run_tests.sh
~~~

Of course, you can also use IPv6 proxies, as well as a combination of IPv4 and IPv6 proxies:

~~~
export LEAK_CI_ALLOW_IP_PROTOCOL=1
export LEAK_CI_ALLOW_IP4_ADDR_PORT="127.0.0.1
9050
127.0.0.1
9150"
export LEAK_CI_ALLOW_IP6_ADDR_PORT="::1
9050
::1
9150"

./detect_leaks.sh ./run_tests.sh
~~~

Let's say your application is expected to access arbitrary ports on `127.0.0.1`.  You can use regular expressions to do this:

~~~
export LEAK_CI_ALLOW_IP_PROTOCOL=1
export LEAK_CI_ALLOW_IP4_ADDR_PORT="127.0.0.1
[0-9]\\+"
export LEAK_CI_ALLOW_IP6_ADDR_PORT=""

./detect_leaks.sh ./run_tests.sh
~~~

Now let's say you're going above and beyond, and only want to use Unix domain sockets (not IP) to talk to the proxy (which makes it easier for AppArmor to protect your application).  You can do that like this:

~~~
export LEAK_CI_ALLOW_IP_PROTOCOL=0
export LEAK_CI_ALLOW_IP4_ADDR_PORT=""
export LEAK_CI_ALLOW_IP6_ADDR_PORT=""

./detect_leaks.sh ./run_tests.sh
~~~

## What's Heteronculous doing under the hood?

It's using `strace` to detect usage of Linux syscalls that relate to networking.  The rest is some small Bash glue that makes it more convenient.

## Does Heteronculous block leaks?

**No!**  All it does is detect them, so that you can fix them yourself.  This is useful as a development and QA tool, but if you're in a situation where a proxy leak might put you in danger, don't use Heteronculous by itself.

## Do transproxies like Whonix and Tails make Heteronculous obsolete?

**No!**  Transproxies like the ones used in Whonix and Tails can't easily enforce stream isolation.  Without stream isolation, you are not anonymous; you are at best pseudonymous.  By far the best way to enforce stream isolation is for all applications to route traffic through Tor's SOCKS port (with SOCKS authentication).  Heteronculous is a great way to notice if an application running in Whonix is accidentally routing some traffic through the Trans port (bad!) instead of the SOCKS port.

## Status

Heteronculous is very new and untested, so it's likely that you'll run into false positive warnings.  Please report them so that I can improve the code!  It's also plausible that you'll run into false negatives, although I hope it's less likely.  Please report those to me too if you run into any.  **Heteronculous may be a useful tool for noticing and debugging proxy leaks, but please don't rely on it exclusively.**

## Bugs Fixed via Heteronculous

* [Gajim DNS leak for SRV records](https://dev.gajim.org/gajim/gajim/issues/8538#note_180861)

## Roadmap

* Detect SOCKS authentication leaks.
* Fix any bugs that people notice.  There will be bugs!

## Etymology

**Spoiler alert: don't read this section if you haven't finished the *Harry Potter* Series!**

I have a bad habit of using obscure multilayered puns for naming my projects.  Here's where the name came from:

* In the *Harry Potter* series, Peter Pettigrew is the villain responsible for leaking the location of Lily, James, and Harry Potter, resulting in the murder of Lily and James.  This is very much akin to proxy leaks resulting in the murder of Muggle activists.
* Pettigrew's role in the leak was discovered using the [Marauder's Map](https://www.pottermore.com/writing-by-jk-rowling/the-marauders-map), which is implemented via the *Homonculous Charm*.
* "Homonculous" is based on a Latin word that loosely translates to "tiny artificial human"; "homo" is Latin for "human".  However, "homo" is also Greek for "same".  A proxy leak detector's primary role is to make sure that multiple identities remain separated, so naturally it makes sense to replace "homo" (same) with "hetero" (Greek for "different"), which gives us *Heteronculous*.
* Any complaints from fundamentalist linguists about the mixing of Latin and Greek will be met with a Bat-Bogey Hex.

### What's up with the slogan?

* Fidelius is akin to Whonix.  It protected the Potters from simple attacks (e.g. Voldemort going looking for them, or a network router detecting your public IP address), but it spectacularly failed to protect them from more esoteric attacks (e.g. Wormtail being a spy, or correlation of identities routed through a pseudonymizing transproxy).
* Mimblewimble is akin to code patches to fix proxy leaks.  The Potters didn't think to use it, because they didn't know Wormtail was meeting with Voldemort.  (Had the Order of the Phoenix used the Homonculous Charm on Wormtail, perhaps they would have figured it out.)  Similarly, you can't patch code that you don't know is leaking; Heteronculous lets you know that your code is leaking so that you can fix it before it leaks your secret location.
* Coincidentally, Phidelius and Mimblewimble are the names of existing cryptography projects.  It seems that bad Harry Potter jokes are quite popular among cypherpunks.

## Credits

* Heteronculous code by Jeremy Rand.  Any bugs are my fault, and you shouldn't blame the following people for any problems you might run into.
* Thanks to pabouk on Tor StackExchange for [suggesting using `strace` for detecting proxy leaks](https://tor.stackexchange.com/a/118).
* Thanks to c00kiemon5ter on StackOverflow for [suggesting using `stdbuf` to fix timing irregularities](https://stackoverflow.com/a/11337109).
* Thanks to Anorov on GitHub for [reporting a proxy leak in PySocks](https://github.com/Anorov/PySocks/issues/22), which was very convenient for testing Heteronculous.
* Thanks to Fitblip on GitHub for [suggesting a way to fix the aforementioned proxy leak in PySocks](https://web.archive.org/web/20161211104525/https://fitblip.pub/2012/11/13/proxying-dns-with-python/), which was very convenient for testing Heteronculous.  (Heteronculous confirms that the bugfix works!)
* Thanks to grarpamp on the tor-talk mailing list for an interesting conversation about this topic.
* Thanks to Filippo Valsorda for his [list of Linux syscalls](https://filippo.io/linux-syscall-table/).
* Thanks to [The Harry Potter Lexicon](https://www.hp-lexicon.org/) for feeding my bad pun addiction.  (Greets to Dan Kaminsky of Phidelius and Tom Elvis Jedusor of Mimblewimble!)
