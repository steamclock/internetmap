#include "traceroute.h"

const char *ip_hdr_key = "vhtslen id  off tlprsum srcip   dstip   opts";

void
pkt_compare(const u_char *a, int la, const u_char *b, int lb) {
	int l;
	int i;

	for (i = 0; i < la; i++)
		Printf("%02x", (unsigned int)a[i]);
	Printf("\n");
	l = (la <= lb) ? la : lb;
	for (i = 0; i < l; i++)
		if (a[i] == b[i])
			Printf("__");
		else
			Printf("%02x", (unsigned int)b[i]);
	for (; i < lb; i++)
		Printf("%02x", (unsigned int)b[i]);
	Printf("\n");
}

void
print(struct traceroute *t, u_char *buf, int cc, struct sockaddr_in *from)
{
	struct ip *ip;
	int hlen;
	char addr[INET_ADDRSTRLEN];

	ip = (struct ip *) buf;
	hlen = ip->ip_hl << 2;
	cc -= hlen;

	strncpy(addr, inet_ntoa(from->sin_addr), sizeof(addr));

	if (t->nflag)
		Printf(" %s", addr);
	else
		Printf(" %s (%s)", traceroute_inetname(t, from->sin_addr), addr);

	if (t->verbose)
		Printf(" %d bytes to %s", cc, inet_ntoa (ip->ip_dst));
}

void
usage(void)
{
	Fprintf(stderr,
	    "Usage: %s [-adDeFInrSvx] [-f first_ttl] [-g gateway] [-i iface]\n"
	    "\t[-m max_ttl] [-p port] [-P proto] [-q nqueries] [-s src_addr]\n"
	    "\t[-t tos] [-w waittime] [-A as_server] [-z pausemsecs] host [packetlen]\n", prog);
	exit(1);
}

int
main_traceroute(int argc, char **argv)
{
	struct traceroute *t = traceroute_alloc();
	int op, code, n;
	char *cp;
	const char *err;
	u_int32_t *ap;
	int probe, i;
	int tos = 0, settos = 0;
	struct ifaddrlist *al;
	char errbuf[132];
	int requestPort = -1;
	int sump = 0;
	int sockerrno;
	const char devnull[] = "/dev/null";
	int printdiff = 0; /* Print the difference between sent and quoted */
	int ret;

	/* Insure the socket fds won't be 0, 1 or 2 */
	if (open(devnull, O_RDONLY) < 0 ||
	    open(devnull, O_RDONLY) < 0 ||
	    open(devnull, O_RDONLY) < 0) {
		Fprintf(stderr, "%s: open \"%s\": %s\n",
		    prog, devnull, strerror(errno));
		exit(1);
	}

	/*
	 * Do the setuid-required stuff first, then lose priveleges ASAP.
	 * Do error checking for these two calls where they appeared in
	 * the original code.
	 */
	traceroute_init(t);
	ret = traceroute_set_proto(t, "icmp");
	if (ret != 0) {
		fprintf(stderr, "traceroute_set_proto failed: %i\n", ret);
		return ret;
	}

	if (argc != 2) {
		fprintf(stderr, "usage: traceroute hostname\n");
		return 1;
	}

	ret = traceroute_set_hostname(t, argv[1]);
	if (ret < 0) {
		fprintf(stderr, "traceroute_set_hostname failed\n");
		return 1;
	}

	ret = traceroute_bind(t);
	if (ret != 0) {
		fprintf(stderr, "traceroute_bind failed: %i\n", ret);
		return ret;
	}

	if (setuid(getuid()) != 0) {
		perror("setuid()");
		exit(1);
	}

	setvbuf(stdout, NULL, _IOLBF, 0);

	/* Print out header */
	Fprintf(stderr, "%s to %s (%s)",
	    prog, t->hostname, inet_ntoa(t->to->sin_addr));
	if (t->source)
		Fprintf(stderr, " from %s", t->source);
	Fprintf(stderr, ", %d hops max, %d byte packets\n", t->max_ttl, t->packlen);
	(void)fflush(stderr);

	TRACEROUTE_FOR_EACH_TTL(t) {
		u_int32_t lastaddr = 0;
		int gotlastaddr = 0;
		int got_there = 0;
		int unreachable = 0;
		int loss = 0;;
		int sleep_for = 1000;
		int max_sleep = 100;

		Printf("%2d ", t->ttl);
		for (probe = 0; probe < t->nprobes; ++probe) {
			int cc;
			struct ip *ip;
			int slept = 0;

			traceroute_send_next_probe(t);

			/* Wait for a reply */
			cc = traceroute_wait_for_reply(t);
			while (cc == 0 && slept < max_sleep) {
				usleep(sleep_for);
				slept++;
				cc = traceroute_wait_for_reply(t);
			}

			while (cc != 0) {
				double T;
				int precis;

				i = traceroute_packet_ok(t, cc);
				/* Skip short packet */
				if (i == 0)
					break;
				if (!gotlastaddr ||
				    t->from->sin_addr.s_addr != lastaddr) {
					if (gotlastaddr) printf("\n   ");
					print(t, t->packet, cc, t->from);
					lastaddr = t->from->sin_addr.s_addr;
					++gotlastaddr;
				}
				T = traceroute_time_delta(t);
#ifdef SANE_PRECISION
				if (T >= 1000.0)
					precis = 0;
				else if (T >= 100.0)
					precis = 1;
				else if (T >= 10.0)
					precis = 2;
				else
#endif
					precis = 3;
				Printf("  %.*f ms", precis, T);
				if (printdiff) {
					Printf("\n");
					Printf("%*.*s%s\n",
					    -(t->outip->ip_hl << 3),
					    t->outip->ip_hl << 3,
					    ip_hdr_key,
					    t->proto->key);
					pkt_compare((void *)t->outip, t->packlen,
					    (void *)t->hip, t->hiplen);
				}
				if (i == -2) {
#ifndef ARCHAIC
					ip = (struct ip *)t->packet;
					if (ip->ip_ttl <= 1)
						Printf(" !");
#endif
					++got_there;
					break;
				}
				/* time exceeded in transit */
				if (i == -1)
					break;

				code = traceroute_packet_code(t, cc);
				switch (code) {

				case ICMP_UNREACH_PORT:
#ifndef ARCHAIC
					ip = (struct ip *)t->packet;
					if (ip->ip_ttl <= 1)
						Printf(" !");
#endif
					++got_there;
					break;

				case ICMP_UNREACH_NET:
					++unreachable;
					Printf(" !N");
					break;

				case ICMP_UNREACH_HOST:
					++unreachable;
					Printf(" !H");
					break;

				case ICMP_UNREACH_PROTOCOL:
					++got_there;
					Printf(" !P");
					break;

				case ICMP_UNREACH_NEEDFRAG:
					++unreachable;
					Printf(" !F-%d", t->pmtu);
					break;

				case ICMP_UNREACH_SRCFAIL:
					++unreachable;
					Printf(" !S");
					break;

				case ICMP_UNREACH_NET_UNKNOWN:
					++unreachable;
					Printf(" !U");
					break;

				case ICMP_UNREACH_HOST_UNKNOWN:
					++unreachable;
					Printf(" !W");
					break;

				case ICMP_UNREACH_ISOLATED:
					++unreachable;
					Printf(" !I");
					break;

				case ICMP_UNREACH_NET_PROHIB:
					++unreachable;
					Printf(" !A");
					break;

				case ICMP_UNREACH_HOST_PROHIB:
					++unreachable;
					Printf(" !Z");
					break;

				case ICMP_UNREACH_TOSNET:
					++unreachable;
					Printf(" !Q");
					break;

				case ICMP_UNREACH_TOSHOST:
					++unreachable;
					Printf(" !T");
					break;

				case ICMP_UNREACH_FILTER_PROHIB:
					++unreachable;
					Printf(" !X");
					break;

				case ICMP_UNREACH_HOST_PRECEDENCE:
					++unreachable;
					Printf(" !V");
					break;

				case ICMP_UNREACH_PRECEDENCE_CUTOFF:
					++unreachable;
					Printf(" !C");
					break;

				default:
					++unreachable;
					Printf(" !<%d>", code);
					break;
				}
				break;
			}
			if (cc == 0) {
				loss++;
				Printf(" *");
			}
			(void)fflush(stdout);
		}
		if (sump) {
			Printf(" (%d%% loss)", (loss * 100) / t->nprobes);
		}
		putchar('\n');
		if (got_there ||
		    (unreachable > 0 && unreachable >= t->nprobes - 1))
			break;
	}
	traceroute_free(t);
	exit(0);
}
