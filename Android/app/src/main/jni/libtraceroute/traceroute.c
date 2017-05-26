/* 
 * Librarization done by Brandon Philips
 * Copyright (c) 2012 Rackspace, Inc
 *
 * Copyright (c) 1988, 1989, 1991, 1994, 1995, 1996, 1997, 1998, 1999, 2000
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that: (1) source code distributions
 * retain the above copyright notice and this paragraph in its entirety, (2)
 * distributions including binary code include the above copyright notice and
 * this paragraph in its entirety in the documentation or other materials
 * provided with the distribution, and (3) all advertising materials mentioning
 * features or use of this software display the following acknowledgement:
 * ``This product includes software developed by the University of California,
 * Lawrence Berkeley Laboratory and its contributors.'' Neither the name of
 * the University nor the names of its contributors may be used to endorse
 * or promote products derived from this software without specific prior
 * written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#include "traceroute.h"
#include "traceroute_private.h"

struct traceroute *
traceroute_alloc() 
{
	return calloc(1, sizeof(struct traceroute));
}

void
traceroute_free(struct traceroute *t) 
{
	return free(t);
}

struct ip *
traceroute__init_outip(struct traceroute *t)
{
	u_short off = 0;

	if (t->outip == NULL)
		free(t->outip);

	t->outip = (struct ip *)malloc((unsigned)t->packlen);
	if (t->outip == NULL)
		return t->outip;

	memset((char *)t->outip, 0, t->packlen);

	t->outip->ip_v = IPVERSION;
#ifdef BYTESWAP_IP_HDR
	t->outip->ip_len = htons(packlen);
	t->outip->ip_off = htons(off);
#else
	t->outip->ip_len = t->packlen;
	t->outip->ip_off = off;
#endif
	t->outip->ip_p = t->proto->num;
	t->outp = (u_char *)(t->outip + 1);
	t->outip->ip_dst = t->to->sin_addr;

	t->outip->ip_hl = (t->outp - (u_char *)t->outip) >> 2;

	t->outip->ip_src = t->from->sin_addr;
	return t->outip;
}

void
traceroute_init(struct traceroute *t) 
{
	t->to = (struct sockaddr_in *)&t->whereto;
	t->from = (struct sockaddr_in *)&t->wherefrom;
	t->proto = &protos[0];
	t->hip = NULL;
	t->hiplen = 0;
	t->maxpacket = 32 * 1024;
	t->max_ttl = 30;
	t->first_ttl = 1;
	t->waittime = 5;
	t->as_server = NULL;
	t->fixedPort = 0;
	t->nprobes = 1;

	t->minpacket = sizeof(*t->outip) + t->proto->hdrlen + sizeof(struct outdata) + t->optlen;
	t->packlen = t->minpacket;			/* minimum sized packet */
	t->protlen = t->packlen - sizeof(*t->outip) - t->optlen;

	t->ident = (getpid() & 0xffff) | 0x8000;
}

void
traceroute_set_ident(struct traceroute *t, u_short ident)
{
	t->ident = ident;
}

int
traceroute_set_hostname(struct traceroute *t, const char *hostname)
{
	struct hostinfo *hi;
	struct ip *outip;
	struct sockaddr_in *to = (struct sockaddr_in *)&t->whereto;

	hi = gethostinfo(hostname);
	if (hi == NULL)
		return -1;
	setsin(to, hi->addrs[0]);
	t->hostname = hi->name;
	hi->name = NULL;
	freehostinfo(hi);

	outip = traceroute__init_outip(t);
	if (outip == NULL)
		return -2;

	return 0;
}

int
traceroute_set_proto(struct traceroute *t, const char *cp)
{
	struct protoent *pe;
	int on = 1;

	pe = getprotobyname(cp);
	if (pe) {
		if ((t->s = socket(AF_INET, SOCK_RAW, pe->p_proto)) < 0) {
			return -errno;
		} else if ((t->sndsock = socket(AF_INET, SOCK_RAW, IPPROTO_RAW)) < 0) {
			return -errno;
		}
	} else if (pe == NULL) {
		return -EINVAL;
	}

	/* sndsock options */
	if (t->options & SO_DEBUG)
		(void)setsockopt(t->s, SOL_SOCKET, SO_DEBUG, (char *)&on,
		    sizeof(on));
	if (t->options & SO_DONTROUTE)
		(void)setsockopt(t->s, SOL_SOCKET, SO_DONTROUTE, (char *)&on,
		    sizeof(on));

	/* sndsock options */
	if (t->options & SO_DEBUG)
		(void)setsockopt(t->sndsock, SOL_SOCKET, SO_DEBUG, (char *)&on,
		    sizeof(on));
	if (t->options & SO_DONTROUTE)
		(void)setsockopt(t->sndsock, SOL_SOCKET, SO_DONTROUTE, (char *)&on,
		    sizeof(on));

	return 0;
}

int
traceroute_bind(struct traceroute *t)
{
	int ret = 0;

	if (t->from == NULL)
		return -EINVAL;
	if (t->sndsock == 0)
		return -EINVAL;

	ret = bind(t->sndsock, (struct sockaddr *)t->from, sizeof(*t->from));

	return ret;
}

int
traceroute_send_probe(struct traceroute *t, int ttl, int seq)
{
	struct outdata *o = &t->outdata;

	/* Prepare outgoing data */
	o->seq = seq;
	o->ttl = ttl;

	/* Avoid alignment problems by copying bytewise: */
	(void)gettimeofday(&t->timesent, NULL);
	memcpy(&o->tv, t, sizeof(o->tv));

	/* Finalize and send packet */
	(*t->proto->prepare)(t, o);
	return send_probe(t, seq, ttl);
}

int
traceroute_send_next_probe(struct traceroute *t)
{
       return traceroute_send_probe(t, t->ttl, ++t->seq);
}

double
traceroute_time_delta(struct traceroute *t)
{
	return deltaT(&t->timesent, &t->timerecv);
}

int
traceroute_wait_for_reply(struct traceroute *t)
{
	fd_set *fdsp;
	size_t nfds;
	struct timeval now, wait;
	int cc = 0;
	int error;
	socklen_t fromlen = sizeof(*t->from);
	int sock = t->s;
	struct sockaddr_in *fromp = t->from;
	struct timeval *tp = &t->timesent;

	nfds = howmany(sock + 1, NFDBITS);
	if ((fdsp = malloc(nfds * sizeof(fd_mask))) == NULL)
		err(1, "malloc");
	memset(fdsp, 0, nfds * sizeof(fd_mask));
	FD_SET(sock, fdsp);

	wait.tv_sec = 0;
	wait.tv_usec = 0;

	error = select(sock + 1, fdsp, NULL, NULL, &wait);
	if (error == -1 && errno == EINVAL) {
		Fprintf(stderr, "%s: botched select() args\n", prog);
		exit(1);
	}
	if (error > 0)
		cc = recvfrom(sock, (char *)t->packet, sizeof(t->packet), 0,
			    (struct sockaddr *)fromp, &fromlen);

	if (cc != 0)
		(void)gettimeofday(&t->timerecv, NULL);

	free(fdsp);
	return(cc);
}

/*
 * Construct an Internet address representation.
 * If the nflag has been supplied, give
 * numeric value, otherwise try for symbolic name.
 */
char *
traceroute_inetname(struct traceroute *t, struct in_addr in)
{
	char *cp;
	struct hostent *hp;
	static int first = 1;
	static char domain[MAXHOSTNAMELEN + 1], line[MAXHOSTNAMELEN + 1];

	if (first && !t->nflag) {
		first = 0;
		if (gethostname(domain, sizeof(domain) - 1) < 0)
			domain[0] = '\0';
		else {
			cp = strchr(domain, '.');
			if (cp == NULL) {
				hp = gethostbyname(domain);
				if (hp != NULL)
					cp = strchr(hp->h_name, '.');
			}
			if (cp == NULL)
				domain[0] = '\0';
			else {
				++cp;
				(void)strncpy(domain, cp, sizeof(domain) - 1);
				domain[sizeof(domain) - 1] = '\0';
			}
		}
	}
	if (!t->nflag && in.s_addr != INADDR_ANY) {
		hp = gethostbyaddr((char *)&in, sizeof(in), AF_INET);
		if (hp != NULL) {
			if ((cp = strchr(hp->h_name, '.')) != NULL &&
			    strcmp(cp + 1, domain) == 0)
				*cp = '\0';
			(void)strncpy(line, hp->h_name, sizeof(line) - 1);
			line[sizeof(line) - 1] = '\0';
			return (line);
		}
	}
	return (inet_ntoa(in));
}

static int
send_probe(struct traceroute *t, int seq, int ttl)
{
	int cc;

	t->outip->ip_ttl = ttl;
	t->outip->ip_id = htons(t->ident + seq);

#if !defined(IP_HDRINCL) && defined(IP_TTL)
	if (setsockopt(t->sndsock, IPPROTO_IP, IP_TTL,
	    (char *)&ttl, sizeof(ttl)) < 0) {
		return -1;
	}
#endif

	cc = sendto(t->sndsock, (char *)t->outip,
	    t->packlen, 0, &t->whereto, sizeof(t->whereto));
	if (cc < 0)
		return errno;

	if (cc != t->packlen)
		return -2;

	return 0;
}

#if	defined(IPSEC) && defined(IPSEC_POLICY_IPSEC)
static int
setpolicy(so, policy)
	int so;
	char *policy;
{
	char *buf;

	buf = ipsec_set_policy(policy, strlen(policy));
	if (buf == NULL) {
		warnx("%s", ipsec_strerror());
		return -1;
	}
	(void)setsockopt(so, IPPROTO_IP, IP_IPSEC_POLICY,
		buf, ipsec_get_policylen(buf));

	free(buf);

	return 0;
}
#endif

static double
deltaT(struct timeval *t1p, struct timeval *t2p)
{
	double dt;

	dt = (t2p->tv_sec - t1p->tv_sec) * 1000.0;
	dt += (t2p->tv_usec - t1p->tv_usec) / 1000.0;

	return dt;
}

/*
 * Convert an ICMP "type" field to a printable string.
 */
static char *
pr_type(u_char t)
{
	static char *ttab[] = {
	"Echo Reply",	"ICMP 1",	"ICMP 2",	"Dest Unreachable",
	"Source Quench", "Redirect",	"ICMP 6",	"ICMP 7",
	"Echo",		"ICMP 9",	"ICMP 10",	"Time Exceeded",
	"Param Problem", "Timestamp",	"Timestamp Reply", "Info Request",
	"Info Reply"
	};

	if (t > 16)
		return("OUT-OF-RANGE");

	return(ttab[t]);
}

int
traceroute_packet_ok(struct traceroute *t, int cc)
{
	struct icmp *icp;
	u_char type, code;
	int hlen;
#ifndef ARCHAIC
	struct ip *ip;
	void * buf = t->packet;

	ip = (struct ip *) t->packet;
	hlen = ip->ip_hl << 2;
	if (cc < hlen + ICMP_MINLEN) {
		return 0;
	}
	cc -= hlen;
	icp = (struct icmp *)(buf + hlen);
#else
	icp = (struct icmp *)buf;
#endif
	type = icp->icmp_type;
	code = icp->icmp_code;
	/* Path MTU Discovery (RFC1191) */
	if (code != ICMP_UNREACH_NEEDFRAG)
		t->pmtu = 0;
	else {
#ifdef HAVE_ICMP_NEXTMTU
		t->pmtu = ntohs(icp->icmp_nextmtu);
#else
		t->pmtu = ntohs(((struct my_pmtu *)&icp->icmp_void)->ipm_nextmtu);
#endif
	}
	if (type == ICMP_ECHOREPLY
	    && t->proto->num == IPPROTO_ICMP
	    && (*t->proto->check)(t, (u_char *)icp, (u_char)t->seq))
		return -2;
	if ((type == ICMP_TIMXCEED && code == ICMP_TIMXCEED_INTRANS) ||
	    type == ICMP_UNREACH) {
		u_char *inner;

		t->hip = &icp->icmp_ip;
		t->hiplen = ((u_char *)icp + cc) - (u_char *)t->hip;
		hlen = t->hip->ip_hl << 2;
		inner = (u_char *)((u_char *)t->hip + hlen);
		if (hlen + 12 <= cc
		    && t->hip->ip_p == t->proto->num
		    && (*t->proto->check)(t, inner, (u_char)t->seq))
			return (type == ICMP_TIMXCEED ? -1 : code + 1);
	}

	return 0;
}

int
traceroute_packet_code(struct traceroute *t, int cc)
{
	return traceroute_packet_ok(t, cc) - 1;
}

static void
icmp_prep(struct traceroute *t, struct outdata *outdata)
{
	struct icmp *const icmpheader = (struct icmp *) t->outp;

	icmpheader->icmp_type = ICMP_ECHO;
	icmpheader->icmp_id = htons(t->ident);
	icmpheader->icmp_seq = htons(outdata->seq);
	icmpheader->icmp_cksum = 0;
	icmpheader->icmp_cksum = in_cksum((u_short *)icmpheader, t->protlen);
	if (icmpheader->icmp_cksum == 0)
		icmpheader->icmp_cksum = 0xffff;
}

static int
icmp_check(struct traceroute *t, const u_char *data, int seq)
{
	struct icmp *const icmpheader = (struct icmp *) data;

	return (icmpheader->icmp_id == htons(t->ident)
	    && icmpheader->icmp_seq == htons(seq));
}

static void
udp_prep(struct traceroute *t, struct outdata *outdata)
{
	struct udphdr *const outudp = (struct udphdr *) t->outp;

	outudp->uh_sport = htons(t->ident + (t->fixedPort ? outdata->seq : 0));
	outudp->uh_dport = htons(t->port + (t->fixedPort ? 0 : outdata->seq));
	outudp->uh_ulen = htons((u_short)t->protlen);
	outudp->uh_sum = 0;

	return;
}

static int
udp_check(struct traceroute *t, const u_char *data, int seq)
{
	struct udphdr *const udp = (struct udphdr *) data;

	return (ntohs(udp->uh_sport) == t->ident + (t->fixedPort ? seq : 0) &&
	    ntohs(udp->uh_dport) == t->port + (t->fixedPort ? 0 : seq));
}

static void
tcp_prep(struct traceroute *t, struct outdata *outdata)
{
	struct tcphdr *const tcp = (struct tcphdr *) t->outp;

	tcp->th_sport = htons(t->ident);
	tcp->th_dport = htons(t->port + (t->fixedPort ? 0 : outdata->seq));
	tcp->th_seq = (tcp->th_sport << 16) | (tcp->th_dport +
	    (t->fixedPort ? outdata->seq : 0));
	tcp->th_ack = 0;
	tcp->th_off = 5;
	tcp->th_flags = TH_SYN;
	tcp->th_sum = 0;
}

static int
tcp_check(struct traceroute *t, const u_char *data, int seq)
{
	struct tcphdr *const tcp = (struct tcphdr *) data;

	return (ntohs(tcp->th_sport) == t->ident
	    && ntohs(tcp->th_dport) == t->port + (t->fixedPort ? 0 : seq))
	    && tcp->th_seq == (((tcp_seq)t->ident << 16) | (t->port + seq));
}

static void
gre_prep(struct traceroute *t, struct outdata *outdata)
{
	struct grehdr *const gre = (struct grehdr *) t->outp;

	gre->flags = htons(0x2001);
	gre->proto = htons(t->port);
	gre->length = 0;
	gre->callId = htons(t->ident + outdata->seq);
}

static int
gre_check(struct traceroute *t, const u_char *data, int seq)
{
	struct grehdr *const gre = (struct grehdr *) data;

	return(ntohs(gre->proto) == t->port
	    && ntohs(gre->callId) == t->ident + seq);
}

static void
gen_prep(struct traceroute *t, struct outdata *outdata)
{
	u_int16_t *const ptr = (u_int16_t *) t->outp;

	ptr[0] = htons(t->ident);
	ptr[1] = htons(t->port + outdata->seq);
}

static int
gen_check(struct traceroute *t, const u_char *data, int seq)
{
	u_int16_t *const ptr = (u_int16_t *) data;

	return(ntohs(ptr[0]) == t->ident
	    && ntohs(ptr[1]) == t->port + seq);
}

/*
 * Checksum routine for Internet Protocol family headers (C Version)
 */
static u_short
in_cksum(u_short *addr, int len)
{
	int nleft = len;
	u_short *w = addr;
	u_short answer;
	int sum = 0;

	/*
	 *  Our algorithm is simple, using a 32 bit accumulator (sum),
	 *  we add sequential 16 bit words to it, and at the end, fold
	 *  back all the carry bits from the top 16 bits into the lower
	 *  16 bits.
	 */
	while (nleft > 1)  {
		sum += *w++;
		nleft -= 2;
	}

	/* mop up an odd byte, if necessary */
	if (nleft == 1)
		sum += *(u_char *)w;

	/*
	 * add back carry outs from top 16 bits to low 16 bits
	 */
	sum = (sum >> 16) + (sum & 0xffff);	/* add hi 16 to low 16 */
	sum += (sum >> 16);			/* add carry */
	answer = ~sum;				/* truncate to 16 bits */
	return (answer);
}

/*
 * Subtract 2 timeval structs:  out = out - in.
 * Out is assumed to be within about LONG_MAX seconds of in.
 */
static void
tvsub(struct timeval *out, struct timeval *in)
{

	if ((out->tv_usec -= in->tv_usec) < 0)   {
		--out->tv_sec;
		out->tv_usec += 1000000;
	}
	out->tv_sec -= in->tv_sec;
}

static struct hostinfo *
gethostinfo(const char *hostname)
{
	int n;
	struct hostent *hp;
	struct hostinfo *hi;
	char **p;
	u_int32_t addr, *ap;

	if (strlen(hostname) >= MAXHOSTNAMELEN)
		return NULL;

	hi = calloc(1, sizeof(*hi));
	if (hi == NULL)
		return NULL;

	addr = inet_addr(hostname);
	if ((int32_t)addr != -1) {
		hi->name = strdup(hostname);
		hi->n = 1;
		hi->addrs = calloc(1, sizeof(hi->addrs[0]));

		if (hi->addrs == NULL)
			goto free_hi;

		hi->addrs[0] = addr;
		return hi;
	}

	hp = gethostbyname(hostname);

	if (hp == NULL)
		goto free_hi;

	if (hp->h_addrtype != AF_INET || hp->h_length != 4)
		goto free_hi;

	hi->name = strdup(hp->h_name);
	for (n = 0, p = hp->h_addr_list; *p != NULL; ++n, ++p)
		continue;

	hi->n = n;

	hi->addrs = calloc(n, sizeof(hi->addrs[0]));
	if (hi->addrs == NULL)
		goto free_hi;

	for (ap = hi->addrs, p = hp->h_addr_list; *p != NULL; ++ap, ++p) {
		memcpy(ap, *p, sizeof(*ap));
	}

	return (hi);

free_hi_addrs:
	free(hi->addrs);

free_hi:
	free(hi);
	hi = NULL;

	return (hi);
}

static void
freehostinfo(struct hostinfo *hi)
{
	if (hi->name != NULL) {
		free(hi->name);
		hi->name = NULL;
	}
	free((char *)hi->addrs);
	free((char *)hi);
}

static void
getaddr(u_int32_t *ap, char *hostname)
{
	struct hostinfo *hi;

	hi = gethostinfo(hostname);
	*ap = hi->addrs[0];
	freehostinfo(hi);
}

static void
setsin(struct sockaddr_in *sin, u_int32_t addr)
{

	memset(sin, 0, sizeof(*sin));
#ifdef HAVE_SOCKADDR_SA_LEN
	sin->sin_len = sizeof(*sin);
#endif
	sin->sin_family = AF_INET;
	sin->sin_addr.s_addr = addr;
}

static struct outproto *
setproto(char *pname)
{
	struct outproto *proto;
	int i;

	for (i = 0; protos[i].name != NULL; i++) {
		if (strcasecmp(protos[i].name, pname) == 0) {
			break;
		}
	}
	proto = &protos[i];
	if (proto->name == NULL) {	/* generic handler */
		struct protoent *pe;
		u_long pnum;

		/* Determine the IP protocol number */
		if ((pe = getprotobyname(pname)) != NULL)
			pnum = pe->p_proto;
		else
			return NULL;
		proto->num = pnum;
	}
	return proto;
}
