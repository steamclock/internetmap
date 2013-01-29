//
//  Node.m
//  InternetMap
//

#include "Node.hpp"
#include <ctype.h>

//lazy loading of generated strings

Node::Node()
:mInitializedFriendly(false)
{}

std::string Node::friendlyDescription() {
    if (!mInitializedFriendly) {
        if (!textDescription.empty()) {
            LOG("original: %s", textDescription.c_str());
            //if the description starts with "signet-as signet..." or "signet signet..."
            //then strip the redundant first word.
            bool stripFirst = false;
            int firstWordEnd = textDescription.find(' ');
            if (firstWordEnd != std::string::npos) {
                std::string firstWord = textDescription.substr(0, firstWordEnd);
                if (firstWord.find('-') != std::string::npos) {
                    //it has a dash, assume it's signet-as
                    stripFirst = true;
                } else {
                    //compare to second word
                    int secondWordStart = firstWordEnd + 1; //note: assuming singlespacing
                    int secondWordEnd = textDescription.find(' ', secondWordStart);
                    int secondWordLen = (secondWordEnd == std::string::npos) ? std::string::npos : (secondWordEnd-secondWordStart);
                    if (textDescription.compare(secondWordStart, secondWordLen, firstWord) == 0) {
                        stripFirst = true;
                    }
                }
            }

            if (stripFirst) {
                mFriendlyDescription = textDescription.substr(firstWordEnd + 1);
            } else {
                mFriendlyDescription = textDescription;
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
            LOG("after upper: %s", mFriendlyDescription.c_str());
        }
        mInitializedFriendly = true;
    }
    return mFriendlyDescription;
}
