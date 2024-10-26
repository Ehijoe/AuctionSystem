import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Time "mo:base/Time";

actor {
  type AuctionId = Nat;
  
  private type BidStore = {
    bidder: Text;
    amount: Nat;
    description: Text;
    time: Time.Time;
  };

  private type AuctionStore = {
    id: AuctionId;
    item: Text;
    description: Text;
    bids: Buffer.Buffer<BidStore>;
    endTime: Time.Time;
    active: Bool;
  };

  public type BidPublic = {
    bidder: Text;
    amount: Nat;
    description: Text;
    time: Time.Time;
  };

  public type AuctionPublic = {
    id: AuctionId;
    item: Text;
    description: Text;
    bids: [BidPublic];
    endTime: Time.Time;
    active: Bool;
  };

  var auctions = Buffer.Buffer<AuctionStore>(0);

  public func createAuction(item: Text, description: Text, duration: Nat) : async AuctionId {
    let auctionId = auctions.size();
    let newAuction: AuctionStore = {
      id = auctionId;
      item = item;
      description = description;
      bids = Buffer.Buffer<BidStore>(0);
      endTime = Time.now() + duration;
      active = true;
    };
    auctions.add(newAuction);
    auctionId
  };

  public func placeBid(auctionId: AuctionId, bidder: Text, amount: Nat, description: Text) : async Bool {
    if (auctionId >= auctions.size()) return false;
    let auction = auctions.get(auctionId);

    let newBid: BidStore = {
      bidder = bidder;
      amount = amount;
      description = description;
      time = Time.now();
    };
    auction.bids.add(newBid);
    true
  };

  public query func getAuction(id: AuctionId) : async ?AuctionPublic {
    if (id >= auctions.size()) {
      return null;
    };
    
    let auction = auctions.get(id);
    let bidsPublic = Buffer.Buffer<BidPublic>(0);
    
    for (bid in auction.bids.vals()) {
      bidsPublic.add({
        bidder = bid.bidder;
        amount = bid.amount;
        description = bid.description;
        time = bid.time;
      });
    };

    ?{
      id = auction.id;
      item = auction.item;
      description = auction.description;
      bids = Buffer.toArray(bidsPublic);
      endTime = auction.endTime;
      active = auction.active;
    }
  };

  public query func getAllAuctions() : async [AuctionPublic] {
    let results = Buffer.Buffer<AuctionPublic>(0);
    
    for (auction in auctions.vals()) {
      let bidsPublic = Buffer.Buffer<BidPublic>(0);
      
      for (bid in auction.bids.vals()) {
        bidsPublic.add({
          bidder = bid.bidder;
          amount = bid.amount;
          description = bid.description;
          time = bid.time;
        });
      };

      results.add({
        id = auction.id;
        item = auction.item;
        description = auction.description;
        bids = Buffer.toArray(bidsPublic);
        endTime = auction.endTime;
        active = auction.active;
      });
    };
    Buffer.toArray(results)
  };

  public func endAuction(auctionId: AuctionId) : async Bool {
    if (auctionId >= auctions.size()) return false;
    let auction = auctions.get(auctionId);
    
    if (Time.now() <= auction.endTime) return false;

    let updatedAuction: AuctionStore = {
      id = auction.id;
      item = auction.item;
      description = auction.description;
      bids = auction.bids;
      endTime = auction.endTime;
      active = false;
    };
    auctions.put(auctionId, updatedAuction);
    true
  };
};