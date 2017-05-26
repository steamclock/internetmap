#ifndef MAXHOSTNAMELEN
#define MAXHOSTNAMELEN	64
#endif

/* rfc1716 */
#ifndef ICMP_UNREACH_FILTER_PROHIB
#define ICMP_UNREACH_FILTER_PROHIB	13	/* admin prohibited filter */
#endif
#ifndef ICMP_UNREACH_HOST_PRECEDENCE
#define ICMP_UNREACH_HOST_PRECEDENCE	14	/* host precedence violation */
#endif
#ifndef ICMP_UNREACH_PRECEDENCE_CUTOFF
#define ICMP_UNREACH_PRECEDENCE_CUTOFF	15	/* precedence cutoff */
#endif

/* Data section of the probe packet */
#ifndef HAVE_ICMP_NEXTMTU
/* Path MTU Discovery (RFC1191) */
struct my_pmtu {
	u_short ipm_void;
	u_short ipm_nextmtu;
};
#endif

/* What a GRE packet header looks like */
struct grehdr {
	u_int16_t   flags;
	u_int16_t   proto;
	u_int16_t   length;	/* PPTP version of these fields */
	u_int16_t   callId;
};
#ifndef IPPROTO_GRE
#define IPPROTO_GRE	47
#endif

/* For GRE, we prepare what looks like a PPTP packet */
#define GRE_PPTP_PROTO	0x880b

static void	udp_prep(struct traceroute *, struct outdata *);
static int	udp_check(struct traceroute *, const u_char *, int);
static void	tcp_prep(struct traceroute *, struct outdata *);
static int	tcp_check(struct traceroute *, const u_char *, int);
static void	gre_prep(struct traceroute *, struct outdata *);
static int	gre_check(struct traceroute *, const u_char *, int);
static void	gen_prep(struct traceroute *, struct outdata *);
static int	gen_check(struct traceroute *, const u_char *, int);
static void	icmp_prep(struct traceroute *, struct outdata *);
static int	icmp_check(struct traceroute *, const u_char *, int);

static struct hostinfo *gethostinfo(const char *hostname);

/* Forwards */
static void	freehostinfo(struct hostinfo *);
static void	getaddr(u_int32_t *, char *);
static struct	hostinfo *gethostinfo(const char *);
static u_short	in_cksum(u_short *, int);
static u_short p_cksum(struct ip *, u_short *, int);
static char	*pr_type(u_char);
#ifdef	IPSEC
static int	setpolicy __P((int so, char *policy));
#endif
static struct outproto *setproto(char *);
static int	str2val(const char *, const char *, int, int);
static void	tvsub(struct timeval *, struct timeval *);
static void usage(void);
static void pkt_compare(const u_char *, int, const u_char *, int);
#ifndef HAVE_USLEEP
int	usleep(u_int);
#endif
static int send_probe(struct traceroute *, int, int);
static double deltaT(struct timeval *t1p, struct timeval *t2p);
static void	setsin(struct sockaddr_in *, u_int32_t);

/* List of supported protocols. The first one is the default. The last
   one is the handler for generic protocols not explicitly listed. */
struct	outproto protos[] = {
	{
		"udp",
		"spt dpt len sum",
		IPPROTO_UDP,
		sizeof(struct udphdr),
		32768 + 666,
		udp_prep,
		udp_check
	},
	{
		"tcp",
		"spt dpt seq     ack     xxflwin sum urp",
		IPPROTO_TCP,
		sizeof(struct tcphdr),
		32768 + 666,
		tcp_prep,
		tcp_check
	},
	{
		"gre",
		"flg pro len clid",
		IPPROTO_GRE,
		sizeof(struct grehdr),
		GRE_PPTP_PROTO,
		gre_prep,
		gre_check
	},
	{
		"icmp",
		"typ cod sum ",
		IPPROTO_ICMP,
		sizeof(struct icmp),
		0,
		icmp_prep,
		icmp_check
	},
	{
		NULL,
		NULL,
		0,
		2 * sizeof(u_short),
		0,
		gen_prep,
		gen_check
	},
};

