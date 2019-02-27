//
//  SCPingUtility.swift
//  Internet Map
//
//  Created by Robert MacEachern on 2019-02-21.
//  Copyright © 2019 Peer1. All rights reserved.
//

import Foundation

@objc protocol SCPingUtilityDelegate {

    /// Invoked immediately before a ping packet is sent.
    func pingUtilityWillSendPing(_ pingUtility: SCPingUtility)

    /// Invoked each time a response packet is received. Includes all packet records seen so far.
    func pingUtility(_ pingUtility: SCPingUtility, didReceiveResponse records: [SCPacketRecord])

    /// Invoked when an error occurs with sending a packet or a more general ICMP failure.
    func pingUtility(_ pingUtility: SCPingUtility, didFailWithError error: Error)

    /// Invoked when the ping utility has finished. Includes all packet records.
    func pingUtility(_ pingUtility: SCPingUtility, didFinishWithRecords records: [SCPacketRecord])
}

@objc class SCPingUtility: NSObject {

    let ipAddress: String
    let count: Int
    let ttl: Int

    /// The interval between sending packets.
    let wait: TimeInterval

    @objc var delegate: SCPingUtilityDelegate?

    @objc public var packetRecords: [SCPacketRecord] {
        let records = icmpUtility.packetRecords
        records.forEach { record in
            // The ICMPHeader sequence numbers are big endian. Need to convert them before looking them up.
            let responseHeader = responsePacketHeaders.first(where: { CFSwapInt16BigToHost($0.0.sequenceNumber) == record.sequenceNumber})
            record.arrival = responseHeader?.1
            record.rtt = responseHeader == nil ? 0 : Float(record.arrival.timeIntervalSince1970 - record.departure.timeIntervalSince1970) * 1000.0
            record.responseAddress = responseHeader == nil ? nil : ipAddress
            record.timedOut = responseHeader == nil && (Date().timeIntervalSince1970 - record.departure.timeIntervalSince1970) > wait
        }
        return records
    }

    private var icmpUtility: SCIcmpPacketUtility
    private var hasStarted: Bool = false
    private var responsePacketHeaders: [(ICMPHeader, arrival: Date)] = []

    @objc init(ipAddress: String, count: Int, ttl: Int, wait: TimeInterval) {
        self.ipAddress = ipAddress
        self.count = count
        self.ttl = ttl
        self.wait = wait
        self.icmpUtility = SCIcmpPacketUtility(hostAddress: ipAddress)
        super.init()
        self.icmpUtility.delegate = self
    }

    @objc func start() {
        guard !hasStarted else {
            NSLog("WARNING: Attempting to restart a SCPingUtility that has alread been started. Create a new instance instead.")
            return
        }
        icmpUtility.start()
        hasStarted = true
    }

    @objc func finish() {
        icmpUtility.stop()
        self.delegate?.pingUtility(self, didFinishWithRecords: packetRecords)
    }

    private func sendPingPacketIfNecessary() {
        if icmpUtility.nextSequenceNumber < count {
            self.delegate?.pingUtilityWillSendPing(self)
            icmpUtility.sendPacket(with: nil, andTTL: ttl)
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                self.sendPingPacketIfNecessary()
            }
        } else {
            NSLog("SCPingUtility reached number of ping packets to send")
            finish()
        }
    }
}

extension SCPingUtility: SCIcmpPacketUtilityDelegate {

    func scIcmpPacketUtility(_ packetUtility: SCIcmpPacketUtility!, didSendPacket packet: Data!) {
        NSLog("SCPingUtility SCIcmpPacketUtility.didSendPacket")
    }

    func scIcmpPacketUtility(_ packetUtility: SCIcmpPacketUtility!, didFailWithError error: Error!) {
        NSLog("SCPingUtility SCIcmpPacketUtility.didFailWithError \(error.localizedDescription)")
        self.delegate?.pingUtility(self, didFailWithError: error)
    }

    func scIcmpPacketUtility(_ packetUtility: SCIcmpPacketUtility!, didStartWithAddress address: Data!) {
        NSLog("SCPingUtility SCIcmpPacketUtility.didStartWithAddress")
        sendPingPacketIfNecessary()
    }

    func scIcmpPacketUtility(_ packetUtility: SCIcmpPacketUtility!, didReceiveUnexpectedPacket packet: Data!) {
        NSLog("SCPingUtility SCIcmpPacketUtility.didReceiveUnexpectedPacket")
    }

    func scIcmpPacketUtility(_ packetUtility: SCIcmpPacketUtility!, didFailToSendPacket packet: Data!, error: Error!) {
        NSLog("didFailToSendPacket \(error.localizedDescription)")
        self.delegate?.pingUtility(self, didFailWithError: error)
    }

    func scIcmpPacketUtility(_ packetUtility: SCIcmpPacketUtility!, didReceiveResponsePacket packet: Data!, arrivedAt dateTime: Date!) {
        NSLog("SCPingUtility SCIcmpPacketUtility.didReceiveResponsePacket at time \(dateTime!)")
        guard let icmpPacket = SCIcmpPacketUtility.icmp(inPacket: packet)?.pointee else {
            fatalError("Unable to access icmp packet")
        }

        responsePacketHeaders.append((icmpPacket, dateTime))
        self.delegate?.pingUtility(self, didReceiveResponse: self.packetRecords)
    }
}
