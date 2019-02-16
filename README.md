FRWL: From Russia with love
===
_(i will try to keep this fork up to date with the original repo in terms of final data naming schemes and general organization, so it can be parsed along with the data from the original repo.)_
## how this fork differs:
 - this fork creates a `selected_servers.txt` this way if you stop and start the script it use the same
 servers it did last time.
 
 - supports comments in `$SERVER_LIST`. specified by a `#`. can be anywhere in the line.
   - `123.456.789` will be processed
   - `#123.456.789` or `123.456#.789` wont.
 
 - the `$ITER` and `$COMP_ITER` variables are handled on a per server basis, and saved to a file. this means you if you stop and restart the script it will pick up right where it left off(it could skip a number if you killed it between the `_increment` call and the the `traceroute`).
 
 - directories are flat. this isnt a huge problem for the `$WORKING_DIR` as there will only ever be around 12K files per folder. but if you were to run it for a **VERY** long time, you could get enough tarballs in the `$TARBALL_DIR` to start causing problems. if i do impliment it, the directories will only be created as needed, instead of creating all of them every loop. (check one directory per loop vs ~1333 per loop)
 <br>ie.
 <br>`RANDOM_DIR=$(_randomDir)`
 <br>`_checkPath "$TARBALL_DIR/$RANDOM_DIR"`
 <br>`tar...$TARBALL_DIR/$RANDOM_DIR/$COMP_ITER...`
 <br>if i decide to implement for `$WORKING_DIR` it will only be ~10 folders (~120 files per folder) generated by `(($ITER % 10))` or something.
 
 - i believe thats most differences, aside from some organization and syntax.
 
 - also ive patched together a tmux_wrapper of sorts, to run multiple instances at a time. **see <a href="#tmux_wrapper">tmux</a> section below**
 
<hr>

link to inception [Reddit thread](https://www.reddit.com/r/DataHoarder/comments/apsd7v/with_russia_going_offline_for_a_test_some_time/)

There is a survey available for those participating: [Google Form](https://goo.gl/forms/l2zbfzblneP6D6sE3)

There is also a place to submit any IPFS hashes of data you've collected: [Google Form](https://goo.gl/forms/o3vXwj4NPzODAttR2)

If you all would like a place to chat I've set up an orbit channel (IPFS based chat): [Orbit Channel](https://orbit.chat/#/channel/frwl) (Just join #frwl by clicking the channel menu in the top left. Seems hot-linking doesn't work.)

Goals
---

- Figure out when the shutdown happens, as well as when everything comes back up. Currently all we know is "before April 1st 2019" that's not good enough.
- Be the first to identify the new "great firewall" infrastructure.
- Keep it decentralized, they can't hack everyone if they get angry.
- Find news and articles to corroborate our findings.
- Keep it running up to a week after Russia comes back online.
- Run some pretty data analysis on it later.


How it do?
---

We will be tracerouting the most nuclear servers I could think of. NTP servers. You can find them on shodan or use this list I've gathered `servers.txt`.

Currently a shell script. Improvements welcome as pull requests.

Data will be hosted on IPFS. The data gets packaged into txz by the shell script as 50MB uncompressed chunks (about 2.3MB max compressed). The data is just the output of a traceroute. When its all done IPFS hashes of your data can be submitted here as pull requests appended to the `hashes.txt` file. Don't forget to add your name to the bottom of this readme if you contribute!

The script creates logs in a weird way. Each file has a unique ID in the set and each set has a unique ID as well. The logs end in either `.new` or `.old` this allows me to use diff tools a little easier.

final logs should be compressed in the same manner in the style `final.servername.yourtimezone.tar.xz` with max compression in the hopes of saving even more space. You can join or stop at any time but please leave an IPFS hash as an issue or a pull request, I'll do my best to pin it as soon as I can. You can use this command to do the final compression:

`xz -9evv --lzma2=dict=128MiB,lc=4,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=1024`

**Read the comments and code before proceeding.**


Current Statistics
---
It's about 14 compressed files a day or 31.5MB per day with a projected size of about 2GB of data per server for the entire 2 month long endeavor.

Guidelines
---

Your traceroute logs should have a bunch of data. but if there are a bunch of `***` next to a hop then you're behind some sort of nasty filtering firewall. Pop a hole in it to get clean data. We want hostnames not just latency. It's probably a good idea to be using a VPN for this. Use one really close to you to cut down on the hops. I highly recommend NordVPN.

Watch for updates to the script they may be important for data processing. You may have to work them into your environment somehow.

If you are editing the code tabs are 4 spaces. Don't make me write a `CONTRIBUTING.md`.


Extra stuff
---

The current shodan query for Russian NTP servers: `ntp country:"RU" port:"123"`

The deduplication script can be used so you can dump any additional IPs at the bottom of the list, then remove any duplicates.



Docker
===

Dockerfile
---

The dockerfile and the ping_russia_docker.sh script has added the arguement variable to the server declaration so that it is passed and not hard set.  `SERVER="" > SERVER="$1"`


Docker Run
---

By creating a script to create multiple containers and volumes to automate launching containers with different IPs will be able to test against many servers easily.

 An image has been provided at https://hub.docker.com/r/danuke/frwl

docker run -d --name frwl -v "localvolume":/from_russia_with_love_comp -e ServerIP="IP/Host" danukefl/frwl

<a id="tmux_wrapper">Tmux</a>
===
`tmux_wrapper.sh` starts a tmux session with x mount of windows, each running `ping_russia.sh`

by default the structure will be the same as just running `ping_russia.sh` in addition to `./tmux_dir`, which is full of directories named after each tmux window. each of these is the working directory of the corrisponding tmux window.

these directories arent used by default(which is recommended), although you can change the paths in `ping_russia.sh` to be relative (ie. `./`) to use the working directories.

Tmux Run
---
**after** you have edited the config/variable sections of both `tmux_wrapper.sh` and `ping_russia.sh`, just run `tmux_wrapper.sh`

you can put also put it in your crontab to automatically restart windows/instances what have died.

`0 * * * * /bin/bash /path/to/tmux_wrapper.sh` will check every hour.

if you dont have any other tmux sessions running you can kill with `tmux kill-server`

or if you just want to kill the tmux_wrapper session, `tmux kill-session -t [session-name]`

by default the session name is `FRWLx$SESSION_NUM`



Contributors
===

We <3 you!
---

- **/u/BigT905 and /u/orangejuice3 for the Shodan results! Massive contribution thank you!**

- /u/meostro: Final compression command.

- Colseph: Awesome script mods

- Danuke: for Dockerfile and image creation.

- gidoBOSSftw5731: FreeBSD support.
