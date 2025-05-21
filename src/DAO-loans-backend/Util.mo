import Random "mo:base/Random";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Float "mo:base/Float";

module {

    public type Subaccount = Blob;

    public func getRandomSubaccount() : async Subaccount {
    let random = Random.Finite(await Random.blob());

    let ArrayBuffer = Buffer.Buffer<Nat8>(32);
    while (ArrayBuffer.size() < 32) {
      let ?byte: ?Nat8 = random.byte() else { Debug.trap("Failed to get random byte") };
      ArrayBuffer.add(byte);
    };

    Blob.fromArray(Buffer.toArray(ArrayBuffer))
  };

  public func divideIntegers(nats: Int, divisor: Int): Int {
    let floatNats = Float.fromInt(nats);
    let floatDivisor = Float.fromInt(divisor);
    let floatQuotient = floatNats / floatDivisor;
    Float.toInt(floatQuotient)
  };

}