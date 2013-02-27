//
//  Node.m
//  InternetMap
//

#include "Node.hpp"
#include <ctype.h>

//lazy loading of generated strings

Node::Node() :
    mInitializedFriendly(false),
    hasLatLong(false),
    latitude(0.0f),
    longitude(0.0f),
    activeDefault(false),
    neverLoaded(false)
{}

std::string Node::friendlyDescription() {
    if (!mInitializedFriendly) {
        if (!rawTextDescription.empty()) {
            //LOG("original: %s", rawTextDescription.c_str());
            //if the description starts with "signet-as signet..." or "signet signet..."
            //then strip the redundant first word.
            bool stripFirst = false;
            int firstWordEnd = rawTextDescription.find(' ');
            if (firstWordEnd != std::string::npos) {
                std::string firstWord = rawTextDescription.substr(0, firstWordEnd);
                if (firstWord.find('-') != std::string::npos) {
                    //it has a dash, assume it's signet-as
                    stripFirst = true;
                } else {
                    //compare to second word
                    int secondWordStart = firstWordEnd + 1; //note: assuming singlespacing
                    int secondWordEnd = rawTextDescription.find(' ', secondWordStart);
                    int secondWordLen = (secondWordEnd == std::string::npos) ? std::string::npos : (secondWordEnd-secondWordStart);
                    if (rawTextDescription.compare(secondWordStart, secondWordLen, firstWord) == 0) {
                        stripFirst = true;
                    }
                }
            }

            if (stripFirst) {
                mFriendlyDescription = rawTextDescription.substr(firstWordEnd + 1);
            } else {
                mFriendlyDescription = rawTextDescription;
            }

            //LOG("before upper: %s", mFriendlyDescription.c_str());
            //now capitalize every word.
            //note: assuming singlespacing (and ascii)
            int prevWordEnd = -1;
            do {
                int wordStart = prevWordEnd + 1;
                mFriendlyDescription[wordStart] = toupper(mFriendlyDescription[wordStart]);
                prevWordEnd = mFriendlyDescription.find(' ', wordStart);
            } while (prevWordEnd != std::string::npos);
            //LOG("after upper: %s", mFriendlyDescription.c_str());
        }
        mInitializedFriendly = true;
    }
    return mFriendlyDescription;
}
