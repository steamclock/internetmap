#ifndef TREACEPATH_H
#define TREACEPATH_H

#include <android/log.h>
#include "tracepath.h"
#include <netinet/in.h>
#include <netinet/ip_icmp.h>

#define LOG(...) __android_log_print(ANDROID_LOG_INFO, "InternetMap", __VA_ARGS__)
#define LOG_INFO(...) __android_log_print(ANDROID_LOG_INFO, "InternetMap", __VA_ARGS__)
#define LOG_ERROR(...) __android_log_print(ANDROID_LOG_ERROR, "InternetMap", __VA_ARGS__)

class Tracepath {

public:
    Tracepath();
    virtual ~Tracepath();
    void runWithDestinationAddress(struct in_addr *dst);

private:
    int setupSocket(struct in_addr *dst);
    bool sendProbe(int sock, sockaddr_in addr, int ttl);
    int receiveError(int sock, int ttl);
    int waitForReply(int sock);
    bool receiveData(int sock);
};

#endif // Tracepath
