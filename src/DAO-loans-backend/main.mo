import Types "types";
import OrderedMap "mo:base/OrderedMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Util "Util";
import ICRC1 "ICRC1";
import Error "mo:base/Error";

shared actor class Contracts() = this {

  let natMap = OrderedMap.Make<Nat>(Nat.compare);
  let principalMap = OrderedMap.Make<Principal>(Principal.compare);

  private stable let DAO_TOKEN_CANISTER_ID: Text = "ixqp7-kqaaa-aaaaq-aaetq-cai";

  private let daoTokenCanister: ICRC1.Self = actor(DAO_TOKEN_CANISTER_ID);
  
  private stable var loanRequestsMap: Types.LoanRequestsOrderedMap = natMap.empty();
  private stable var loanRequestId: Nat = 0;

  private stable var loanAgreementsMap: Types.LoanAgreementsOrderedMap = natMap.empty();

  private stable var userProfilesMap: Types.UserProfilesOrderedMap = principalMap.empty();

  public func getRandomSubaccount(): async Util.Subaccount { await Util.getRandomSubaccount() };
  
  public shared({caller}) func createLoanRequest(request: Types.LoanRequest): async Types.UserProfile {

    //check if collateral has been sent to subaccountId
    let subaccountBalance = await daoTokenCanister.icrc1_balance_of({owner = Principal.fromActor(this); subaccount = ?request.subaccountId});
    if(subaccountBalance < request.collateralOffered) { throw Error.reject("Not enough collateral sent to subaccountId") };

    //TODO: Create an SNS proposal after confirming collateral has been sent to subaccountId

    // add request to loanRequestsMap
    loanRequestsMap := natMap.put(loanRequestsMap, loanRequestId, request);

    // add request to userProfilesMap
    let updatedUserProfile = switch(principalMap.get(userProfilesMap, caller)) {
      case(null) { {activeLoans = []; loanHistory = []; loanRequests = [loanRequestId]}; };
      case(?{activeLoans; loanHistory; loanRequests}) { 
        let loanRequestsBuffer = Buffer.fromArray<Types.LoanId>(loanRequests);
        loanRequestsBuffer.add(loanRequestId);
        {activeLoans; loanHistory; loanRequests = loanRequestsBuffer.toArray()};
      };
    };

    userProfilesMap := principalMap.put(userProfilesMap, caller, updatedUserProfile);
    loanRequestId += 1;

    return updatedUserProfile;
  };

  public query func getLoanRequest(requestId: Types.LoanId): async Types.LoanRequest {
    switch(natMap.get(loanRequestsMap, requestId)) { case(null) { throw Error.reject("Loan request not found") }; case(?request) { request }; };
  };

  public query func getLoanRequests(): async Types.LoanRequestsArray { natMap.toArray(loanRequestsMap); };

  public shared({caller}) func deleteLoanRequest(requestId: Types.LoanId): async () {
    //TODO: check if caller is the SNS DAO Canister that is allowed to delete requests
    let ?request = natMap.get(loanRequestsMap, requestId) else return;
    if(not Principal.equal(request.requestor, caller)) { throw Error.reject("You are not allowed to delete this request") };
    let subaccountBalance = await daoTokenCanister.icrc1_balance_of({owner = Principal.fromActor(this); subaccount = ?request.subaccountId});
    let icrc1_fee = await daoTokenCanister.icrc1_fee();
    if(subaccountBalance > 0 and subaccountBalance > icrc1_fee) { 
      ignore await daoTokenCanister.icrc1_transfer({
        from_subaccount = ?request.subaccountId;
        to = {owner = request.requestor; subaccount = null};
        amount = subaccountBalance - icrc1_fee;
        memo = null;
        created_at_time = null;
        fee = ?icrc1_fee;
      });
    };
    loanRequestsMap := natMap.delete(loanRequestsMap, requestId); 
    return;
  };

  private func createLoanAgreement(loanId: Types.LoanId): async () {
    // add agreement to loanAgreementsMap
    //TODO: Send ICP to the requestor

    let ?loanRequest = natMap.get(loanRequestsMap, loanId) else return;
    let paymentsBuffer = Buffer.Buffer<(Types.DateAsText, Types.Payment)>(0);
    let paymentAmount = Util.divideIntegers(loanRequest.amountRequested + loanRequest.loanInterest, loanRequest.numberOfPayments);
    for(i in Iter.range(1, loanRequest.numberOfPayments)) {
      let paymentDate = Time.now() + (i * loanRequest.paymentTermPeriod);
      paymentsBuffer.add((paymentDate, {owed = paymentAmount}));
    };
    let agreement: Types.LoanAgreement = {
      loanRequest with
      amountBorrowed = loanRequest.amountRequested;
      collateralLocked = loanRequest.initialCollateralLocked;
      collateralForfeited = 0;
      payments = paymentsBuffer.toArray();
    };
    let ?userProfile = principalMap.get(userProfilesMap, loanRequest.requestor) else throw Error.reject("User profile not found");
    let updatedActiveLoansBuffer = Buffer.fromArray<Types.LoanId>(userProfile.activeLoans);
    let updatedLoanHistoryBuffer = Buffer.fromArray<Types.LoanId>(userProfile.loanHistory);
    let updatedLoanRequestsBuffer = Buffer.fromArray<Types.LoanId>(userProfile.loanRequests);

    updatedActiveLoansBuffer.add(loanId);
    updatedLoanHistoryBuffer.add(loanId);
    let ?index = updatedLoanRequestsBuffer.indexOf(loanId) else throw Error.reject("Loan request not found");
    updatedLoanRequestsBuffer.delete(index);

    let updatedUserProfile = {
      activeLoans = Buffer.toArray(updatedActiveLoansBuffer);
      loanHistory = Buffer.toArray(updatedLoanHistoryBuffer);
      loanRequests = Buffer.toArray(updatedLoanRequestsBuffer);
    };

    loanAgreementsMap := natMap.put(loanAgreementsMap, loanId, agreement);
    loanRequestsMap := natMap.delete(loanRequestsMap, loanId);
    userProfilesMap := principalMap.put(userProfilesMap, loanRequest.requestor, updatedUserProfile);
  };

  public func getLoanAgreement(agreementId: Types.LoanAgreementId): Types.LoanAgreement {
    // get agreement from loanAgreementsMap
    // return agreement
  };

  public func getLoanAgreements(): Types.LoanAgreementsArray {
    // get all agreements from loanAgreementsMap
    // return agreements
  };

  public func getUserProfile(principal: Principal): Types.UserProfile {
    // get user profile from userProfilesMap
    // return user profile
  };

  public func getUserProfiles(): Types.UserProfilesArray {
    // get all user profiles from userProfilesMap
    // return user profiles
  };

};
