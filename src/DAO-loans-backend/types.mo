import HashMap "mo:base/HashMap";
import OrderedMap "mo:base/OrderedMap";
import Principal "mo:base/Principal";

module{

    public type DateAsText = Text;

    public type Payment = { owed: Nat };

    public type PaymentsArray = [(DateAsText, Payment)];

    public type LoanId = Nat;

    public type LoanRequest = {
        numberOfPayments: Nat;
        paymentTermPeriod: Nat;
        loanInterest: Nat;
        amountRequested: Nat;
        initialCollateralLocked: Nat;
        subaccountId: Blob;
        requestor: Principal;
    };

    public type LoanRequestsArray = [(LoanId, LoanRequest)];

    public type LoanRequestsOrderedMap = OrderedMap.Map<LoanId, LoanRequest>;

    public type LoanAgreement = {
        subaccountId: Blob;
        numberOfPayments: Nat;
        paymentTermPeriod: Nat;
        amountBorrowed: Nat;
        initialCollateralLocked: Nat;
        collateralLocked: Nat;
        collateralForfeited: Nat;
        payments: PaymentsArray;
        loanInterest: Nat;
    };

    public type LoanAgreementsArray = [(LoanId, LoanAgreement)];

    public type LoanAgreementsOrderedMap = OrderedMap.Map<LoanId, LoanAgreement>;

    public type UserProfile = { activeLoans: [LoanId]; loanHistory: [LoanId]; loanRequests: [LoanId] };

    public type UserProfilesArray = [(Principal, UserProfile)];

    public type UserProfilesMap = HashMap.HashMap<Principal, UserProfile>;

    public type UserProfilesOrderedMap = OrderedMap.Map<Principal, UserProfile>;

};