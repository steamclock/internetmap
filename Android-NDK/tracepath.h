#ifndef TREACEPATH_H
#define TREACEPATH_H

#include <android/log.h>
#include "tracepath.h"
#include <netinet/in.h>
#include <netinet/ip_icmp.h>
#include <time.h>
#include <stdlib.h>
#include <vector>
#include <string>

#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "InternetMap", __VA_ARGS__)
#define LOG_INFO(...) __android_log_print(ANDROID_LOG_INFO, "InternetMap", __VA_ARGS__)
#define LOG_ERROR(...) __android_log_print(ANDROID_LOG_ERROR, "InternetMap", __VA_ARGS__)

struct tracepath_hop {
    bool success = false;
    int error;
    int ttl;
    std::string receive_addr;
    struct timeval sendtime;
    struct timeval receievetime;
};

struct probe_result {
    bool success = false;
    std::string receive_addr;
};

typedef std::vector<tracepath_hop> tracepath_hop_vec;

class Tracepath {

public:
    Tracepath();
    virtual ~Tracepath();
    std::vector<tracepath_hop> runWithDestinationAddress(struct in_addr *dst);
    probe_result probeDestinationAddressWithTTL(struct in_addr *dst, int ttl);

private:
    int setupSocket(struct in_addr *dst);
    bool sendProbe(int sock, sockaddr_in addr, int ttl, int attempt, tracepath_hop &probe);
    bool receiveError(int sock, int ttl, tracepath_hop &probe);
    int waitForReply(int sock);
    bool receiveData(int sock, tracepath_hop &probe);
};

#endif // Tracepath
