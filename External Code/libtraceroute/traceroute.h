/*
 * Copyright (c) 2000
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
 *
 * @(#) $Id: traceroute.h,v 1.1 2000/11/23 20:06:54 leres Exp $ (LBL)
 */

#define Fprintf (void)fprintf
#define Printf (void)printf

static char prog[] = "traceroute";

#define _BSD_SOURCE 

#include <sys/param.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#ifdef HAVE_SYS_SELECT_H
#include <sys/select.h>
#endif
#include <sys/socket.h>
#ifdef HAVE_SYS_SYSCTL_H
#include <sys/sysctl.h>
#endif
#include <sys/time.h>


#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
//#include <netinet/ip_icmp.h>
#include "ip_icmp.h"
//#include <netinet/udp.h>
#include "udp.h"
#include <netinet/tcp.h>
#include <arpa/inet.h>

#ifdef	IPSEC
#include <net/route.h>
#include <netipsec/ipsec.h>	/* XXX */
#endif	/* IPSEC */

#include <ctype.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#ifdef HAVE_MALLOC_H
#include <malloc.h>
#endif
#include <memory.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifdef __APPLE__
//#include <netinet/ip_var.h>
#include "ip_var.h"
#endif

/* Maximum number of gateways (include room for one noop) */
#define NGATEWAYS ((int)((MAX_IPOPTLEN - IPOPT_MINOFF - 1) / sizeof(u_int32_t)))

struct outdata {
	u_char seq;		/* sequence number of this packet */
	u_char ttl;		/* ttl packet left with */
	struct timeval tv;	/* time packet left */
};

/* struct traceroute - describes a traceroute */
struct traceroute {
	struct outproto *proto;
	u_char	packet[512];		/* last inbound (icmp) packet */
	struct outdata outdata;

	struct ip *outip;		/* last output ip packet */
	u_char *outp;		/* last output inner protocol packet */

	struct timeval timesent;
	struct timeval timerecv;

	struct ip *hip;		/* Quoted IP header */
	int hiplen;

	/* loose source route gateway list (including room for final destination) */
	u_int32_t gwlist[NGATEWAYS + 1];

	int s;				/* receive (icmp) socket file descriptor */
	int sndsock;			/* send (udp) socket file descriptor */

	struct sockaddr whereto;	/* Who to try to reach */
	struct sockaddr wherefrom;	/* Who we are */
	struct sockaddr_in *to;
	struct sockaddr_in *from;
	int packlen;                    /* total length of packet */
	int protlen;			/* length of protocol part of packet */
	int minpacket;			/* min ip packet size */
	int maxpacket;	/* max ip packet size */
	int pmtu;			/* Path MTU Discovery (RFC1191) */
	u_int pausemsecs;

	char *prog;
	char *source;
	char *hostname;
	char *device;

	int nprobes;
	int max_ttl;
	int first_ttl;
	u_short ident;
	u_short port;			/* protocol specific base "port" */

	int options;			/* socket options */
	int verbose;
	int waittime;		/* time to wait for response (in seconds) */
	int nflag;			/* print addresses numerically */
	int as_path;			/* print as numbers for each hop */
	char *as_server;
	void *asn;
	int optlen;			/* length of ip options */
	int fixedPort;		/* Use fixed destination port for TCP and UDP */
	int ttl;
	int seq;
};

/* traceroute methods */
struct traceroute * traceroute_alloc(void);
void traceroute_free(struct traceroute *);

void traceroute_init(struct traceroute *);
int traceroute_set_hostname(struct traceroute *t, const char *hostname);
int traceroute_bind(struct traceroute *t);
int traceroute_set_proto(struct traceroute *t, const char *cp);
int traceroute_wait_for_reply(struct traceroute *);
double traceroute_time_delta(struct traceroute *);
int traceroute_send_next_probe(struct traceroute *);
int traceroute_packet_ok(struct traceroute *t, int);
char *traceroute_inetname(struct traceroute *t, struct in_addr);
int traceroute_packet_code(struct traceroute *t, int cc);

#define TRACEROUTE_FOR_EACH_TTL(t) \
	 for (t->ttl = t->first_ttl; t->ttl <= t->max_ttl; t->ttl++)

/* Descriptor structure for each outgoing protocol we support */
struct outproto {
	char	*name;		/* name of protocol */
	const char *key;	/* An ascii key for the bytes of the header */
	u_char	num;		/* IP protocol number */
	u_short	hdrlen;		/* max size of protocol header */
	u_short	port;		/* default base protocol-specific "port" */
	void	(*prepare)(struct traceroute *, struct outdata *);
				/* finish preparing an outgoing packet */
	int	(*check)(struct traceroute *, const u_char *, int);
				/* check an incoming packet */
};

/* Host name and address list */
struct hostinfo {
	char *name;
	int n;
	u_int32_t *addrs;
};



