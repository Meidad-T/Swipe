import Foundation
import MultipeerConnectivity
import os
import Combine

#if os(iOS)
import UIKit
#endif

class MultipeerManager: NSObject, ObservableObject {
    static let shared = MultipeerManager()
    
    private let serviceType = "swipe-cont"
    private var myPeerId: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    let logger = Logger(subsystem: "com.swipe", category: "MultipeerManager")
    
    @Published var connectedPeers: [MCPeerID] = []
    
    // Callback to handle incoming URLs
    var onURLReceived: ((URL) -> Void)?

    override init() {
        super.init()
        setupPeer()
    }
    
    private func setupPeer() {
        #if os(macOS)
        let name = Host.current().localizedName ?? "Mac"
        #else
        let name = UIDevice.current.name
        #endif
        
        self.myPeerId = MCPeerID(displayName: name)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
        
        start()
    }
    
    func start() {
        logger.info("Starting Multipeer Advertiser and Browser")
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stop() {
        logger.info("Stopping Multipeer")
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
    }
    
    func send(url: URL) {
        guard !session.connectedPeers.isEmpty else {
            logger.warning("No connected peers to send URL.")
            return
        }
        do {
            let data = url.absoluteString.data(using: .utf8)!
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            logger.info("Sent URL payload to peers.")
        } catch {
            logger.error("Failed to send URL: \(error.localizedDescription)")
        }
    }
}

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            switch state {
            case .connected:
                self.logger.info("Connected to peer: \(peerID.displayName)")
            case .connecting:
                self.logger.info("Connecting to peer: \(peerID.displayName)")
            case .notConnected:
                self.logger.info("Disconnected from peer: \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let string = String(data: data, encoding: .utf8), let url = URL(string: string) {
            self.logger.info("Received URL from peer: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.onURLReceived?(url)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        self.logger.info("Received invitation from peer: \(peerID.displayName). Accepting.")
        invitationHandler(true, self.session)
    }
}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        self.logger.info("Found peer: \(peerID.displayName). Inviting.")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.logger.info("Lost peer: \(peerID.displayName).")
    }
}
