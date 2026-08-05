// Centralized data models and type definitions for the SailPoint API interactions.

// ---- Core References ----

export interface SourceRef {
    id: string;
    name?: string;
    type?: string;
}

export interface EntitlementRef {
    type: "ENTITLEMENT";
    id: string;
    name?: string;
    source?: SourceRef;
}

export interface AccessRef {
    type: "ENTITLEMENT" | "ACCESS_PROFILE" | "ROLE";
    id: string;
    name?: string;
    source?: SourceRef;
}

export interface AccessProfileRef {
    id: string;
    name?: string;
    type: "ACCESS_PROFILE";
    entitlements?: EntitlementRef[];
}

// ---- Access Model (for requested items) ----

export interface AccessModelAttributeValue {
    name: string;
    status: string;
    value: string;
}

export interface AccessModelAttribute {
    description?: string;
    key: string;
    multiselect?: boolean;
    name?: string;
    objectTypes?: string[];
    status?: string;
    type?: string;
    values?: AccessModelAttributeValue[];
}

export interface AccessModelMetadata {
    attributes?: AccessModelAttribute[];
}

export interface GetRequestedItems {
    id?: string;
    type?: "ACCESS_PROFILE" | "ENTITLEMENT" | "ROLE";
    accessModelMetadata?: AccessModelMetadata;
    accessProfiles?: AccessProfileRef[];
    entitlements?: EntitlementRef[];
    [key: string]: unknown;
}

// ---- SOD (Segregation of Duties) ----

export interface ViolatedPolicy {
    type: string;
    id: string;
    name: string;
}

export interface ViolationCheckResult {
    message?: {
        locale: string;
        localeOrigin: string;
        text: string;
    };
    violatedPolicies?: ViolatedPolicy[] | null;
}

export interface SodViolationContext {
    state: string;
    violationCheckResult?: ViolationCheckResult;
    uuid?: string;
}

export interface SodPolicyCriteriaItem {
    type: "ENTITLEMENT";
    id: string;
    name?: string;
}

export interface SodPolicyCriteriaSide {
    name?: string;
    criteriaList: SodPolicyCriteriaItem[];
}

export interface SodPolicy {
    id: string;
    name: string;
    conflictingAccessCriteria?: {
        leftCriteria: SodPolicyCriteriaSide;
        rightCriteria: SodPolicyCriteriaSide;
    } | null;
    [key: string]: unknown;
}

export interface DetectedViolation {
    policyId: string;
    policyName: string;
    matchedLeft: string[];
    matchedRight: string[];
}

export interface IdentityWithNewAccess {
    identityId: string;
    accessRefs: AccessRef[];
}

export interface ViolationPrediction {
    identityId?: string;
    violationContexts?: unknown[];
    message?: {
        locale: string;
        localeOrigin: string;
        text: string;
    };
    [key: string]: unknown;
}

// ---- Access Requests ----

export interface GetAccessRequestStatus {
    id?: string;
    name?: string;
    type?: "ACCESS_PROFILE" | "ENTITLEMENT" | "ROLE";
    accessRequestId?: string;
    requestedFor?: { id: string; name?: string; type?: string };
    sodViolationContext?: SodViolationContext;
    [key: string]: unknown;
}


export interface OpenAccessRequestItem {
    id: string;
    name?: string;
    type: string;
    state?: string;
    accessRequestId?: string;
    requestedFor?: { id: string; name?: string; type?: string };
    [key: string]: unknown;
}

export interface AccessRequestStatusPayload {
    getAccessRequestStatus?: GetAccessRequestStatus | null;
    getRequestedItems?: GetRequestedItems | null;
    getXdrData?: XdrData | null;
}

export interface CheckSodPendingRequestBody {
    identityId: string;
}

// ---- Roles, Profiles, Entitlements Details ----

export interface RoleDetail {
    id: string;
    name?: string;
    entitlements?: EntitlementRef[];
    accessProfiles?: AccessProfileRef[];
    [key: string]: unknown;
}

export interface AccessProfileDetail {
    id: string;
    name?: string;
    source?: SourceRef;
    entitlements?: EntitlementRef[];
    [key: string]: unknown;
}

export interface EntitlementDetail {
    id: string;
    name?: string;
    source?: SourceRef;
    [key: string]: unknown;
}

// ---- Recommendations API ----

export interface RecommendationResponse {
  request: RecommendationRequestItem;
  recommendation: "YES" | "NO" | "MAYBE";
  interpretations: string[];
  translationMessages: unknown[];
  recommenderCalculations: unknown;
}

export interface RecommendationApiResponse {
  responses: RecommendationResponse[];
}

export interface RecommendationRequestItem {
  identityId: string;
  item: {
    id: string;
    type: "ACCESS_PROFILE" | "ENTITLEMENT" | "ROLE";
  };
}

export interface RecommendationRequestBody {
  requests: RecommendationRequestItem[];
  excludeInterpretations?: string;
  includeTranslationMessages?: string;
  includeDebugInformation?: string;
  prescribeMode?: string;
}

// ---- XDR (Risk) Data ----

export interface XdrData {
    attributes?: {
        department?: string | null;
        displayName?: string | null;
        jobTitle?: string | null;
        location?: string | null;
        manager?: string | null;
    };
    firstDetectionDate?: string;
    id?: string;
    identityId?: string;
    ignoreDate?: string | null;
    ignored?: boolean;
    latestDetectionDate?: string;
    score?: number;
    type?: string;
    unignoreDate?: string | null;
    unignoreType?: string | null;
}

export interface AccessRequestItem {
    name: string;
    id: string;
    sodViolationContext?: SodViolationContext;
    [key: string]: unknown;
}
