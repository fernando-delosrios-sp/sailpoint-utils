import { Router } from 'express';
import type { Request, Response } from 'express';

import { getApiBaseUrlFromToken } from '../utils/auth.utils.js';
import { SailPointClient } from '../api/sailpoint.client.js';
import { AccessService } from '../services/access.service.js';
import { SodService } from '../services/sod.service.js';
import { RecommendationService } from '../services/recommendation.service.js';
import { WorkgroupService } from '../services/workgroup.service.js';
import type { AccessRequestStatusPayload, EntitlementRef } from '../api/api.types.js';

const router = Router();



// =========================================================================
// HAUPT-ENDPUNKT: /access-request-status
// =========================================================================
router.post('/access-request-status', async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Missing or invalid Authorization header' });
      return;
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      res.status(401).json({ error: 'Invalid token format in Authorization header' });
      return;
    }

    const apiBaseUrl = getApiBaseUrlFromToken(token);
    if (!apiBaseUrl) {
      res.status(401).json({ error: 'Could not extract API base URL from token' });
      return;
    }

    // --- Services und Payload-Variablen initialisieren ---
    const client = new SailPointClient({ apiBaseUrl, token });
    const accessService = new AccessService(client);
    const sodService = new SodService(client);
    const recService = new RecommendationService(client);

    const payload: AccessRequestStatusPayload = req.body;
    const { getAccessRequestStatus, getRequestedItems, getXdrData } = payload;

    if (!getAccessRequestStatus?.requestedFor?.id || !getAccessRequestStatus.type || !getAccessRequestStatus.id) {
      res.status(400).json({ error: 'Invalid payload: getAccessRequestStatus or required sub-properties missing.' });
      return;
    }

    const identityId = getAccessRequestStatus.requestedFor.id;
    const requestedItemId = getAccessRequestStatus.id!;
    const requestedType = getAccessRequestStatus.type as 'ENTITLEMENT' | 'ACCESS_PROFILE' | 'ROLE';

    // 1. Alle relevanten Daten (Entitlements, pending Entitlements & Metadaten des Items) parallel abrufen
    const [requestedEntitlements, pendingEntitlements, accessModelMetadata] = await Promise.all([
      accessService.getUnderlyingEntitlements(payload),
      accessService.getPendingEntitlements(identityId, getAccessRequestStatus.accessRequestId!),
      accessService.getRequestedItemMetadata(requestedItemId, requestedType)
    ]);

    const allEntitlementsMap = new Map<string, EntitlementRef>();
    pendingEntitlements.forEach(ent => allEntitlementsMap.set(ent.id, ent));
    requestedEntitlements.forEach(ent => allEntitlementsMap.set(ent.id, ent));
    const combinedEntitlements = Array.from(allEntitlementsMap.values());

    // 2. Parallele Abfrage der Risiko-Daten
    const accessRefsPayload = requestedEntitlements.map(ent => ({ id: ent.id, type: 'ENTITLEMENT' as const }));
    const [policies, predictedViolations, recommendations] = await Promise.all([
      sodService.fetchSodPolicies(),
      accessRefsPayload.length > 0 ? sodService.predictSodViolations(identityId, accessRefsPayload) : Promise.resolve(null),
      recService.fetchRecommendations(identityId, requestedItemId, requestedType)
    ]);

    // 3. Lokale SoD-Prüfung durchführen
    const localViolations = sodService.checkPoliciesAgainstEntitlements(combinedEntitlements, policies);

    // --- WORKFLOW-SICHERE STRINGS ERZEUGEN ---

    // a) Für 'violatedPolicyNames'
    const violatedPolicyNamesSet = new Set<string>();
    localViolations.forEach(v => violatedPolicyNamesSet.add(v.policyName));
    const contextViolations = getAccessRequestStatus.sodViolationContext?.violationCheckResult?.violatedPolicies;
    if (contextViolations && Array.isArray(contextViolations)) {
      contextViolations.forEach(p => { if (p.name) violatedPolicyNamesSet.add(p.name); });
    }
    const violatedPolicyNamesString = Array.from(violatedPolicyNamesSet).join(', ') || 'N/A';

    // b) Für 'recommendations'
    const recResponses = recommendations?.responses || [];
    let recommendationsDecision = 'N/A';
    let recommendationsInterpretations = 'N/A';
    if (recResponses.length > 0 && recResponses[0]) {
      const firstRecommendation = recResponses[0];
      recommendationsDecision = firstRecommendation.recommendation || 'N/A';
      if (firstRecommendation.interpretations?.length) {
        recommendationsInterpretations = firstRecommendation.interpretations.join(' | ');
      }
    }
    
    // c) Für 'predictedViolations'
    let sodPredictionString = 'N/A';
    if (predictedViolations && Array.isArray(predictedViolations) && predictedViolations.length > 0) {
        const predictedPolicyNames = predictedViolations
            .map(violation => violation?.policy?.name)
            .filter((name): name is string => !!name);
        
        if (predictedPolicyNames.length > 0) {
            sodPredictionString = predictedPolicyNames.join(', ');
        }
    }

    // d) Andere Werte (iscRisk aus API, xdrScore aus Payload)
    const xdrScorePercent = (getXdrData?.score !== undefined && getXdrData.score !== null) ? `${(getXdrData.score * 100).toFixed(2)}%` : 'N/A';
    const iscRiskName = accessModelMetadata?.attributes?.find((attr: any) => attr.key === 'iscRisk')?.values?.[0]?.name ?? 'N/A';
    
    // 4. Finale Response zusammenbauen
    res.status(200).json({
      accessRefs: requestedEntitlements,
      allOpenEntitlements: pendingEntitlements,
      // getAccessRequestStatus: getAccessRequestStatus,
      // getRequestedItems: getRequestedItems || null,
      // getXdrData: getXdrData || null,
      internalViolations: localViolations,
      iscRiskName: iscRiskName,
      
      // Workflow-sichere String-Felder:
      violatedPolicyNames: violatedPolicyNamesString,
      recommendationsDecision: recommendationsDecision,
      recommendationsInterpretations: recommendationsInterpretations,
      sodPrediction: sodPredictionString,
      xdrScore: xdrScorePercent
    });

  } catch (error) {
    console.error('[Status Endpoint] Error in processing access request status:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});



// =========================================================================
// NEUER ENDPUNKT: /govgroup-emails
// Holt alle E-Mail-Adressen der Mitglieder einer bestimmten Workgroup
// =========================================================================
router.post('/govgroup-emails', async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Missing or invalid Authorization header' });
      return;
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      res.status(401).json({ error: 'Invalid token format in Authorization header' });
      return;
    }

    const apiBaseUrl = getApiBaseUrlFromToken(token);
    if (!apiBaseUrl) {
      res.status(401).json({ error: 'Could not extract API base URL from token' });
      return;
    }

    const { groupName } = req.body;
    if (!groupName) {
      res.status(400).json({ error: 'Missing "groupName" in request body' });
      return;
    }

    const client = new SailPointClient({ apiBaseUrl, token });
    const workgroupService = new WorkgroupService(client);

    console.log(`[GovGroup Endpoint] Resolving emails for group: "${groupName}"`);

    // 1. Hole die ID der Gruppe
    const workgroupId = await workgroupService.getWorkgroupIdByName(groupName);
    if (!workgroupId) {
      res.status(404).json({ error: `Workgroup with name "${groupName}" not found.` });
      return;
    }

    // 2. Hole die E-Mail-Liste als kommagetrennten String
    const emailsString = await workgroupService.getWorkgroupMembersEmails(workgroupId);

    // 3. Gib das Ergebnis exakt wie gewünscht zurück
    res.status(200).json({
      emails: emailsString
    });

  } catch (error) {
    console.error('[GovGroup Endpoint] Error processing request:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// =========================================================================
// ENDPUNKT: /access-request-threshold
// Prüft, ob ein beantragtes Objekt (Rolle/Profil) zusammen mit dem
// bestehenden und parallel offenen Zugriff mehr Entitlements aus einer 
// bestimmten Source enthält, als der Schwellenwert (threshold) erlaubt.
// =========================================================================
router.post('/access-request-threshold', async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Missing or invalid Authorization header' });
      return;
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      res.status(401).json({ error: 'Invalid token format in Authorization header' });
      return;
    }

    const apiBaseUrl = getApiBaseUrlFromToken(token);
    if (!apiBaseUrl) {
      res.status(401).json({ error: 'Could not extract API base URL from token' });
      return;
    }

    const payload = req.body;
    
    // Werte aus dem Payload extrahieren
    const sourceName = payload['sourceName'] || payload.source?.name;
    const thresholdValue = payload['thresholdValue'] ?? payload.threshold?.value;
    
    // Identitäts-ID sicher aus dem getAccessRequestStatus extrahieren
    const identityId = payload.getAccessRequestStatus?.requestedFor?.id;

    if (!payload.getAccessRequestStatus || !identityId || !sourceName || thresholdValue === undefined) {
      res.status(400).json({ error: 'Invalid payload: missing getAccessRequestStatus, requestedFor.id, source.name, or threshold.value' });
      return;
    }

    const client = new SailPointClient({ apiBaseUrl, token });
    const accessService = new AccessService(client);

    console.log(`[Threshold Endpoint] Checking requested item against threshold > ${thresholdValue} for source "${sourceName}" (Identity: ${identityId})`);

    // 1. Alle 3 Quellen PARALLEL abfragen (maximale Performance)
    const [requestedEntitlements, pendingEntitlements, grantedEntitlements] = await Promise.all([
      accessService.getUnderlyingEntitlements(payload), // 1. Neu aus dem aktuellen Antrag
      accessService.getPendingEntitlements(identityId, payload.getAccessRequestStatus.accessRequestId!), // 2. Andere offene Anträge
      accessService.getGrantedEntitlements(identityId) // 3. Bereits existierende, zugewiesene Rechte
    ]);

    // 2. Kombinieren aller Listen (Deduplizierung über die Map anhand der Entitlement ID)
    const allEntitlementsMap = new Map<string, EntitlementRef>();
    grantedEntitlements.forEach(ent => allEntitlementsMap.set(ent.id, ent));
    pendingEntitlements.forEach(ent => allEntitlementsMap.set(ent.id, ent));
    requestedEntitlements.forEach(ent => allEntitlementsMap.set(ent.id, ent));
    const combinedEntitlements = Array.from(allEntitlementsMap.values());

    // 3. Filtern auf die übermittelte Source (Eindeutiger Variablenname zur Fehlervermeidung)
    const thresholdSourceEntitlements = combinedEntitlements.filter(ent => 
      ent.source && ent.source.name && ent.source.name.toLowerCase() === sourceName.toLowerCase()
    );

    const count = thresholdSourceEntitlements.length;

    // 4. Schwellenwert prüfen (Threshold überschritten, wenn strikt größer)
    const isThresholdHit = count > thresholdValue;

    console.log(`[Threshold Endpoint] Result: Found ${count} total entitlements for source "${sourceName}". Hit: ${isThresholdHit}`);

    // 5. Response senden
    res.status(200).json({
      "thresholdHit": isThresholdHit,
      "details": {
        "identityId": identityId,
        "source": sourceName,
        "threshold": thresholdValue,
        "foundCount": count,
        "breakdown": {
          "requested": requestedEntitlements.length,
          "pending": pendingEntitlements.length,
          "granted": grantedEntitlements.length
        }
      }
    });

  } catch (error) {
    console.error('[Threshold Endpoint] Error processing request:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// =========================================================================
// NEUER ENDPUNKT: /check-sod-pending
// Prüft eine Identität präventiv auf SoD-Verstöße, wenn ALLE aktuell offenen
// Anträge (kombiniert mit dem bestehenden Zugriff) genehmigt würden.
// =========================================================================
router.post('/check-sod-pending', async (req: Request, res: Response): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Missing or invalid Authorization header' });
      return;
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      res.status(401).json({ error: 'Invalid token format in Authorization header' });
      return;
    }

    const apiBaseUrl = getApiBaseUrlFromToken(token);
    if (!apiBaseUrl) {
      res.status(401).json({ error: 'Could not extract API base URL from token' });
      return;
    }

    // 1. Hole die identityId dynamisch aus dem empfangenen POST-Body
    const { identityId } = req.body;
    if (!identityId) {
      res.status(400).json({ error: 'Missing "identityId" in request body' });
      return;
    }

    const client = new SailPointClient({ apiBaseUrl, token });
    const accessService = new AccessService(client);
    const sodService = new SodService(client);

    console.log(`[Check-SoD-Pending] Evaluating identity: ${identityId}`);

    // 2. Rufe parallel alle offenen Anträge (pending), bestehenden Rechte (granted) 
    // und die SoD-Richtlinien (policies) für diese spezifische Identität ab.
    // Wir übergeben 'none' als Ausschluss-ID, damit ALLE offenen Anträge geladen werden.
    const [pendingEntitlements, grantedEntitlements, policies] = await Promise.all([
      accessService.getPendingEntitlements(identityId, 'none'),
      accessService.getGrantedEntitlements(identityId),
      sodService.fetchSodPolicies()
    ]);

    // 3. Kombiniere beide Berechtigungsquellen und dedupliziere sie über eine Map
    const allEntitlementsMap = new Map<string, EntitlementRef>();
    grantedEntitlements.forEach((ent: EntitlementRef) => allEntitlementsMap.set(ent.id, ent));
    pendingEntitlements.forEach((ent: EntitlementRef) => allEntitlementsMap.set(ent.id, ent));
    const combinedEntitlements = Array.from(allEntitlementsMap.values());

    // 4. Führe die lokale SoD-Prüfung gegen die kombinierten Berechtigungen aus
    const localViolations = sodService.checkPoliciesAgainstEntitlements(combinedEntitlements, policies);

    // 5. Extrahiere die Namen der verletzten Policies als flachen, kommagetrennten String
    const violatedPolicyNamesSet = new Set<string>();
    localViolations.forEach(v => violatedPolicyNamesSet.add(v.policyName));
    const violatedPolicyNamesString = Array.from(violatedPolicyNamesSet).join(', ') || 'N/A';

    // 6. Gib das präventive Analyse-Ergebnis zurück
    res.status(200).json({
      identityId,
      hasViolations: localViolations.length > 0, // Schnelle Ja/Nein-Entscheidung für deinen Workflow
      violatedPolicyNames: violatedPolicyNamesString, // "Policy A, Policy B" statt ["Policy A", "Policy B"]
      violationsDetails: localViolations, // Volle Details für detaillierte E-Mails oder Logs
      counts: {
        pendingEntitlements: pendingEntitlements.length,
        grantedEntitlements: grantedEntitlements.length,
        combinedTotal: combinedEntitlements.length
      }
    });

  } catch (error) {
    console.error('[Check-SoD-Pending] Error processing request:', error);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});



export default router;
