"""Access request and access revoke templates (version 1: `$user`, `${PRODUCT_NAME}`)."""

from build_templates import Rewrite, bullets, button, details, info, li, note, p, quote, subheading
from catalog_common import OBJECT_TYPE

PN = "${PRODUCT_NAME}"

# `$emeaStatusHtml`: translated, bold "approved"/"denied" (agrees with "request" in every language).
STATUS = """
#if($approved)#set($emeaStatusHtml = "<strong>$tx_statusApproved</strong>")#else#set($emeaStatusHtml = "<strong>$tx_statusDenied</strong>")#end
"""

FOR_OTHER = """
#set($emeaForOther = false)#if($requesterName != $requestedForIdentityName)#set($emeaForOther = true)#end
"""

JIT_NOTE = (
    "<strong>This entitlement must be activated before each use.</strong> Go to MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Este derecho debe activarse antes de cada uso.</strong> Ve a MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Ce droit d’accès doit être activé avant chaque utilisation.</strong> Accédez à MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Questa autorizzazione deve essere attivata prima di ogni utilizzo.</strong> Vai a MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Diese Berechtigung muss vor jeder Nutzung aktiviert werden.</strong> Öffnen Sie MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Este direito de acesso tem de ser ativado antes de cada utilização.</strong> Aceda a MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>يجب تفعيل هذا الاستحقاق قبل كل استخدام.</strong> انتقل إلى MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
)

COMMENT_FROM = (
    "$rejecterName left this comment:",
    "$rejecterName ha dejado este comentario:",
    "$rejecterName a laissé ce commentaire :",
    "$rejecterName ha lasciato questo commento:",
    "$rejecterName hat diesen Kommentar hinterlassen:",
    "$rejecterName deixou este comentário:",
    "ترك $rejecterName هذا التعليق:",
)

CONTACT_REJECTER = (
    "If you have any questions, contact $rejecterName.",
    "Si tienes alguna pregunta, ponte en contacto con $rejecterName.",
    "Pour toute question, contactez $rejecterName.",
    "Per qualsiasi domanda, contatta $rejecterName.",
    "Bei Fragen wenden Sie sich an $rejecterName.",
    "Se tiver alguma dúvida, contacte $rejecterName.",
    "إذا كانت لديك أي أسئلة، فتواصل مع $rejecterName.",
)

CONTACT_REQUESTER = (
    "If you need more information, contact $requesterName.",
    "Si necesitas más información, ponte en contacto con $requesterName.",
    "Pour plus d’informations, contactez $requesterName.",
    "Per ulteriori informazioni, contatta $requesterName.",
    "Weitere Informationen erhalten Sie von $requesterName.",
    "Se precisar de mais informações, contacte $requesterName.",
    "إذا احتجت إلى مزيد من المعلومات، فتواصل مع $requesterName.",
)

DECISION_PENDING = (
    "If approval is required, you will be notified when a decision is made.",
    "Si se requiere aprobación, recibirás una notificación cuando se tome una decisión.",
    "Si une approbation est requise, vous serez informé dès qu’une décision sera prise.",
    "Se è necessaria un’approvazione, riceverai una notifica quando verrà presa una decisione.",
    "Falls eine Genehmigung erforderlich ist, werden Sie über die Entscheidung informiert.",
    "Se for necessária aprovação, será notificado quando for tomada uma decisão.",
    "إذا كانت الموافقة مطلوبة، فسنُعلمك عند اتخاذ القرار.",
)

DATE_ROWS = [("$tx_startsOn", "${startDate}", "$startDate"), ("$tx_endsOn", "${removeDate}", "$removeDate")]


def by_type(with_start: bool = True) -> str:
    """Items grouped by type from `$requestedObjectDetailsByType`."""
    start = "#if($detail.startDate) · $tx_startsOn: ${detail.startDate}#end" if with_start else ""
    item = li("<strong>${detail.name}</strong>" + start + "#if($detail.removeDate) · $tx_endsOn: ${detail.removeDate}#end")
    return (
        "#foreach($type in ${requestedObjectDetailsByType.keySet()})\n"
        + subheading("$type")
        + "\n"
        + bullets("#foreach($detail in ${requestedObjectDetailsByType.get($type)})" + item + "#end")
        + "\n#end"
    )


ITEMS_SAMPLE = {"requestedObjectDetailsByType": "list:"}

TEMPLATES = [
    Rewrite(
        key="access_request_decision",
        greet="${user.name}",
        subject=(
            "#if($approved)Approved#{else}Denied#end: your access request for ${requestedObjectName}",
            "#if($approved)Aprobada#{else}Denegada#end: tu solicitud de acceso a ${requestedObjectName}",
            "#if($approved)Approuvée#{else}Refusée#end : votre demande d’accès à ${requestedObjectName}",
            "#if($approved)Approvata#{else}Rifiutata#end: la tua richiesta di accesso a ${requestedObjectName}",
            "#if($approved)Genehmigt#{else}Abgelehnt#end: Ihre Zugriffsanfrage für ${requestedObjectName}",
            "#if($approved)Aprovado#{else}Recusado#end: o seu pedido de acesso a ${requestedObjectName}",
            "#if($approved)تمت الموافقة#{else}تم الرفض#end: طلب الوصول الخاص بك إلى ${requestedObjectName}",
        ),
        prelude=OBJECT_TYPE
        + STATUS
        + FOR_OTHER
        + """
#if($roleRequestEnabled)#set($emeaItem = "$requestedObjectName")#else#set($emeaItem = "$accessProfileName")#set($emeaType = $tx_typeAccessProfile)#end
""",
        strings={
            "decisionSelf": (
                "Your request for <strong>$emeaItem</strong> ($emeaType) has been $emeaStatusHtml.",
                "Tu solicitud de <strong>$emeaItem</strong> ($emeaType) ha sido $emeaStatusHtml.",
                "Votre demande d’accès à <strong>$emeaItem</strong> ($emeaType) a été $emeaStatusHtml.",
                "La tua richiesta per <strong>$emeaItem</strong> ($emeaType) è stata $emeaStatusHtml.",
                "Ihre Anfrage für <strong>$emeaItem</strong> ($emeaType) wurde $emeaStatusHtml.",
                "O seu pedido de <strong>$emeaItem</strong> ($emeaType) foi $emeaStatusHtml.",
                "طلبك للحصول على <strong>$emeaItem</strong> ($emeaType) $emeaStatusHtml.",
            ),
            "decisionOther": (
                "Your request for <strong>$emeaItem</strong> ($emeaType) for <strong>${requestedForIdentityName}</strong> has been $emeaStatusHtml.",
                "Tu solicitud de <strong>$emeaItem</strong> ($emeaType) para <strong>${requestedForIdentityName}</strong> ha sido $emeaStatusHtml.",
                "Votre demande d’accès à <strong>$emeaItem</strong> ($emeaType) pour <strong>${requestedForIdentityName}</strong> a été $emeaStatusHtml.",
                "La tua richiesta per <strong>$emeaItem</strong> ($emeaType) per conto di <strong>${requestedForIdentityName}</strong> è stata $emeaStatusHtml.",
                "Ihre Anfrage für <strong>$emeaItem</strong> ($emeaType) für <strong>${requestedForIdentityName}</strong> wurde $emeaStatusHtml.",
                "O seu pedido de <strong>$emeaItem</strong> ($emeaType) para <strong>${requestedForIdentityName}</strong> foi $emeaStatusHtml.",
                "طلبك للحصول على <strong>$emeaItem</strong> ($emeaType) لـ <strong>${requestedForIdentityName}</strong> $emeaStatusHtml.",
            ),
            "includesSelf": (
                "You now have access to:",
                "Ahora tienes acceso a:",
                "Vous avez désormais accès à :",
                "Ora hai accesso a:",
                "Sie haben jetzt Zugriff auf:",
                "Passou a ter acesso a:",
                "أصبح لديك الآن وصول إلى:",
            ),
            "includesOther": (
                "${requestedForIdentityName} now has access to:",
                "${requestedForIdentityName} tiene ahora acceso a:",
                "${requestedForIdentityName} a désormais accès à :",
                "${requestedForIdentityName} ora ha accesso a:",
                "${requestedForIdentityName} hat jetzt Zugriff auf:",
                "${requestedForIdentityName} passou a ter acesso a:",
                "أصبح لدى ${requestedForIdentityName} الآن وصول إلى:",
            ),
            "jit": JIT_NOTE,
            "commentFrom": COMMENT_FROM,
            "contactRejecter": CONTACT_REJECTER,
        },
        content=f"""
#if($emeaForOther)
{p("$tx_decisionOther")}
#else
{p("$tx_decisionSelf")}
#end
#if($approved)
#if($roleRequestEnabled && $accessibleItems && $accessibleItems.size() > 0)
#if($emeaForOther){p("$tx_includesOther")}#else{p("$tx_includesSelf")}#end
{bullets("#foreach($item in $accessibleItems)" + li("$item") + "#end")}
#end
#if($startDate || $removeDate)
{details(DATE_ROWS)}
#end
#if($activationRequired && !$emeaForOther)
{info("$tx_jit")}
#end
#else
#if($reviewerComment)
{p("$tx_commentFrom")}
{quote("$reviewerComment")}
#end
{p("$tx_contactRejecter")}
#end
""",
    ),
    Rewrite(
        key="access_request_decision_email_for_requested-for_identity",
        greet="${user.name}",
        subject=(
            "#if($approved)Approved#{else}Denied#end: access ${requesterName} requested for you",
            "#if($approved)Aprobada#{else}Denegada#end: la solicitud de acceso de ${requesterName} para ti",
            "#if($approved)Approuvée#{else}Refusée#end : la demande d’accès de ${requesterName} pour vous",
            "#if($approved)Approvata#{else}Rifiutata#end: la richiesta di accesso di ${requesterName} per te",
            "#if($approved)Genehmigt#{else}Abgelehnt#end: Zugriffsanfrage von ${requesterName} für Sie",
            "#if($approved)Aprovado#{else}Recusado#end: o pedido de acesso de ${requesterName} para si",
            "#if($approved)تمت الموافقة#{else}تم الرفض#end: الوصول الذي طلبه ${requesterName} لك",
        ),
        prelude=STATUS,
        strings={
            "intro": (
                "On ${dateRequested}, ${requesterName} requested <strong>${requestedObjectName}</strong> for you. The request has been $emeaStatusHtml.",
                "El ${dateRequested}, ${requesterName} solicitó <strong>${requestedObjectName}</strong> para ti. La solicitud ha sido $emeaStatusHtml.",
                "Le ${dateRequested}, ${requesterName} a demandé <strong>${requestedObjectName}</strong> pour vous. La demande a été $emeaStatusHtml.",
                "Il ${dateRequested}, ${requesterName} ha richiesto <strong>${requestedObjectName}</strong> per te. La richiesta è stata $emeaStatusHtml.",
                "Am ${dateRequested} hat ${requesterName} <strong>${requestedObjectName}</strong> für Sie angefordert. Die Anfrage wurde $emeaStatusHtml.",
                "Em ${dateRequested}, ${requesterName} pediu <strong>${requestedObjectName}</strong> para si. O pedido foi $emeaStatusHtml.",
                "في ${dateRequested}، طلب ${requesterName} <strong>${requestedObjectName}</strong> لك. الطلب $emeaStatusHtml.",
            ),
            "processing": (
                "Your access is now being set up.",
                "Ya se está configurando tu acceso.",
                "Votre accès est en cours de configuration.",
                "Il tuo accesso è in fase di configurazione.",
                "Ihr Zugriff wird jetzt eingerichtet.",
                "O seu acesso está a ser configurado.",
                "يجري الآن إعداد وصولك.",
            ),
            "jit": JIT_NOTE,
            "commentFrom": COMMENT_FROM,
            "contactRejecter": CONTACT_REJECTER,
        },
        content=f"""
{p("$tx_intro")}
#if($approved)
{p("$tx_processing")}
#if($startDate || $removeDate)
{details(DATE_ROWS)}
#end
#if($activationRequired)
{info("$tx_jit")}
#end
#else
#if($reviewerComment)
{p("$tx_commentFrom")}
{quote("$reviewerComment")}
#else
{p("$tx_contactRejecter")}
#end
#end
""",
    ),
    Rewrite(
        key="access_request_reviewer",
        greet="${user.name}",
        subject=(
            "Review needed: access request for ${requestedForIdentityName}",
            "Revisión pendiente: solicitud de acceso para ${requestedForIdentityName}",
            "Examen requis : demande d’accès pour ${requestedForIdentityName}",
            "Revisione richiesta: richiesta di accesso per ${requestedForIdentityName}",
            "Prüfung erforderlich: Zugriffsanfrage für ${requestedForIdentityName}",
            "Revisão necessária: pedido de acesso para ${requestedForIdentityName}",
            "مراجعة مطلوبة: طلب وصول لـ ${requestedForIdentityName}",
        ),
        prelude=OBJECT_TYPE + FOR_OTHER,
        strings={
            "intro": (
                "${requesterName} has requested <strong>${requestedObjectName}</strong> ($emeaType). Please review the request.",
                "${requesterName} ha solicitado <strong>${requestedObjectName}</strong> ($emeaType). Revisa la solicitud.",
                "${requesterName} a demandé <strong>${requestedObjectName}</strong> ($emeaType). Veuillez examiner la demande.",
                "${requesterName} ha richiesto <strong>${requestedObjectName}</strong> ($emeaType). Esamina la richiesta.",
                "${requesterName} hat <strong>${requestedObjectName}</strong> ($emeaType) angefordert. Bitte prüfen Sie die Anfrage.",
                "${requesterName} pediu <strong>${requestedObjectName}</strong> ($emeaType). Reveja o pedido.",
                "طلب ${requesterName} <strong>${requestedObjectName}</strong> ($emeaType). يُرجى مراجعة الطلب.",
            ),
            "reason": (
                "Reason given by ${requesterName}:",
                "Motivo indicado por ${requesterName}:",
                "Motif indiqué par ${requesterName} :",
                "Motivazione fornita da ${requesterName}:",
                "Begründung von ${requesterName}:",
                "Motivo indicado por ${requesterName}:",
                "السبب الذي قدّمه ${requesterName}:",
            ),
            "includes": (
                "If approved, ${requestedForIdentityName} will get access to:",
                "Si se aprueba, ${requestedForIdentityName} obtendrá acceso a:",
                "En cas d’approbation, ${requestedForIdentityName} aura accès à :",
                "Se approvata, ${requestedForIdentityName} otterrà l’accesso a:",
                "Bei Genehmigung erhält ${requestedForIdentityName} Zugriff auf:",
                "Se for aprovado, ${requestedForIdentityName} terá acesso a:",
                "في حال الموافقة، سيحصل ${requestedForIdentityName} على وصول إلى:",
            ),
            "includesProfile": (
                "If approved, ${requestedForIdentityName} will get every entitlement in ${accessProfileName}.",
                "Si se aprueba, ${requestedForIdentityName} obtendrá todos los derechos de ${accessProfileName}.",
                "En cas d’approbation, ${requestedForIdentityName} obtiendra tous les droits d’accès de ${accessProfileName}.",
                "Se approvata, ${requestedForIdentityName} otterrà tutte le autorizzazioni di ${accessProfileName}.",
                "Bei Genehmigung erhält ${requestedForIdentityName} alle Berechtigungen aus ${accessProfileName}.",
                "Se for aprovado, ${requestedForIdentityName} terá todos os direitos de acesso de ${accessProfileName}.",
                "في حال الموافقة، سيحصل ${requestedForIdentityName} على جميع الاستحقاقات في ${accessProfileName}.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{details([("$tx_requestedBy", "${requesterName}"), ("$tx_requestedFor", "${requestedForIdentityName}"), *DATE_ROWS])}
#if($requesterComments)
{p("$tx_reason")}
{quote("${requesterComments}")}
#end
#if($requestedObjectType == "Role" && $accessibleItems && $accessibleItems.size() > 0)
{p("$tx_includes")}
{bullets("#foreach($item in $accessibleItems)" + li("$item") + "#end")}
#elseif($requestedObjectType == "AccessProfile")
{p("$tx_includesProfile")}
#end
{button("$identityNowUrl/ui/d/approvals", "$tx_reviewNow")}
""",
        sample={"requesterComments": "Needed for the Q4 close."},
    ),
    Rewrite(
        key="access_request_reassignment",
        greet="${newOwnerName}",
        subject=(
            "Review needed: access request from ${requesterName} reassigned to you",
            "Revisión pendiente: se te ha reasignado la solicitud de acceso de ${requesterName}",
            "Examen requis : la demande d’accès de ${requesterName} vous a été réattribuée",
            "Revisione richiesta: ti è stata riassegnata la richiesta di accesso di ${requesterName}",
            "Prüfung erforderlich: Zugriffsanfrage von ${requesterName} wurde Ihnen zugewiesen",
            "Revisão necessária: o pedido de acesso de ${requesterName} foi-lhe reatribuído",
            "مراجعة مطلوبة: أُعيد إليك إسناد طلب وصول من ${requesterName}",
        ),
        prelude=OBJECT_TYPE,
        strings={
            "intro": (
                "${previousOwnerName} has reassigned ${requesterName}’s request for <strong>${requestedObjectName}</strong> ($emeaType) to you for review.",
                "${previousOwnerName} te ha reasignado la solicitud de ${requesterName} de <strong>${requestedObjectName}</strong> ($emeaType) para que la revises.",
                "${previousOwnerName} vous a réattribué la demande de ${requesterName} pour <strong>${requestedObjectName}</strong> ($emeaType) afin que vous l’examiniez.",
                "${previousOwnerName} ti ha riassegnato la richiesta di ${requesterName} per <strong>${requestedObjectName}</strong> ($emeaType) da esaminare.",
                "${previousOwnerName} hat Ihnen die Anfrage von ${requesterName} für <strong>${requestedObjectName}</strong> ($emeaType) zur Prüfung zugewiesen.",
                "${previousOwnerName} reatribuiu-lhe o pedido de ${requesterName} de <strong>${requestedObjectName}</strong> ($emeaType) para revisão.",
                "أعاد ${previousOwnerName} إليك إسناد طلب ${requesterName} للحصول على <strong>${requestedObjectName}</strong> ($emeaType) لمراجعته.",
            ),
            "reason": (
                "Reason for reassignment:",
                "Motivo de la reasignación:",
                "Motif de la réattribution :",
                "Motivo della riassegnazione:",
                "Grund für die Neuzuweisung:",
                "Motivo da reatribuição:",
                "سبب إعادة الإسناد:",
            ),
            "includes": (
                "If you approve, the user will get access to:",
                "Si la apruebas, el usuario obtendrá acceso a:",
                "Si vous l’approuvez, l’utilisateur aura accès à :",
                "Se la approvi, l’utente otterrà l’accesso a:",
                "Wenn Sie genehmigen, erhält der Benutzer Zugriff auf:",
                "Se aprovar, o utilizador terá acesso a:",
                "إذا وافقت، فسيحصل المستخدم على وصول إلى:",
            ),
            "includesProfile": (
                "If you approve, ${requesterName} will get every entitlement in ${accessProfileName}.",
                "Si la apruebas, ${requesterName} obtendrá todos los derechos de ${accessProfileName}.",
                "Si vous l’approuvez, ${requesterName} obtiendra tous les droits d’accès de ${accessProfileName}.",
                "Se la approvi, ${requesterName} otterrà tutte le autorizzazioni di ${accessProfileName}.",
                "Wenn Sie genehmigen, erhält ${requesterName} alle Berechtigungen aus ${accessProfileName}.",
                "Se aprovar, ${requesterName} terá todos os direitos de acesso de ${accessProfileName}.",
                "إذا وافقت، فسيحصل ${requesterName} على جميع الاستحقاقات في ${accessProfileName}.",
            ),
        },
        content=f"""
{p("$tx_intro")}
#if($commentText)
{p("$tx_reason")}
{quote("${commentText}")}
#end
#if($startDate || $removeDate)
{details(DATE_ROWS)}
#end
#if($requestedObjectType == "Role" && $accessibleItems && $accessibleItems.size() > 0)
{p("$tx_includes")}
{bullets("#foreach($item in $accessibleItems)" + li("$item") + "#end")}
#elseif($requestedObjectType == "AccessProfile")
{p("$tx_includesProfile")}
#end
""",
        sample={"newOwnerName": "Lena Müller", "previousOwnerName": "Marco Rossi", "commentText": "I am out of office this week."},
    ),
    Rewrite(
        key="access_request_submitted_email_for_requested-for_identity",
        greet="${user.name}",
        subject=(
            "${requesterName} has requested access for you",
            "${requesterName} ha solicitado acceso para ti",
            "${requesterName} a demandé un accès pour vous",
            "${requesterName} ha richiesto un accesso per te",
            "${requesterName} hat Zugriff für Sie angefordert",
            "${requesterName} pediu acesso para si",
            "طلب ${requesterName} وصولًا لك",
        ),
        strings={
            "intro": (
                "${requesterName} has requested the following access for you:",
                "${requesterName} ha solicitado el siguiente acceso para ti:",
                "${requesterName} a demandé l’accès suivant pour vous :",
                "${requesterName} ha richiesto il seguente accesso per te:",
                "${requesterName} hat folgenden Zugriff für Sie angefordert:",
                "${requesterName} pediu o seguinte acesso para si:",
                "طلب ${requesterName} الوصول التالي لك:",
            ),
            "pending": DECISION_PENDING,
        },
        content=f"""
{p("$tx_intro")}
{by_type()}
{p("$tx_pending")}
""",
        sample=ITEMS_SAMPLE,
    ),
    Rewrite(
        key="access_request_submitted_email_for_requester_after_validation",
        greet="${user.name}",
        subject=(
            "Your access request #if($requestDetails && $requestDetails.size() == 1)for $requestDetails.get(0).identityName #elseif($requestDetails.size() > 1)for $requestDetails.size() people #{end}was submitted",
            "Tu solicitud de acceso #if($requestDetails && $requestDetails.size() == 1)para $requestDetails.get(0).identityName #elseif($requestDetails.size() > 1)para $requestDetails.size() personas #{end}se ha enviado",
            "Votre demande d’accès #if($requestDetails && $requestDetails.size() == 1)pour $requestDetails.get(0).identityName #elseif($requestDetails.size() > 1)pour $requestDetails.size() personnes #{end}a été envoyée",
            "La tua richiesta di accesso #if($requestDetails && $requestDetails.size() == 1)per $requestDetails.get(0).identityName #elseif($requestDetails.size() > 1)per $requestDetails.size() persone #{end}è stata inviata",
            "Ihre Zugriffsanfrage #if($requestDetails && $requestDetails.size() == 1)für $requestDetails.get(0).identityName #elseif($requestDetails.size() > 1)für $requestDetails.size() Personen #{end}wurde gesendet",
            "O seu pedido de acesso #if($requestDetails && $requestDetails.size() == 1)para $requestDetails.get(0).identityName #elseif($requestDetails.size() > 1)para $requestDetails.size() pessoas #{end}foi enviado",
            "تم إرسال طلب الوصول الخاص بك#if($requestDetails && $requestDetails.size() == 1) لـ $requestDetails.get(0).identityName#elseif($requestDetails.size() > 1) لـ $requestDetails.size() أشخاص#end",
        ),
        strings={
            "intro": (
                "Here is a summary of the access you requested:",
                "Este es el resumen del acceso que has solicitado:",
                "Voici un récapitulatif de l’accès que vous avez demandé :",
                "Ecco un riepilogo dell’accesso che hai richiesto:",
                "Hier ist eine Übersicht über den von Ihnen angeforderten Zugriff:",
                "Este é o resumo do acesso que pediu:",
                "إليك ملخص الوصول الذي طلبته:",
            ),
            "submitted": ("Submitted", "Enviado", "Envoyé", "Inviato", "Gesendet", "Enviado", "تم الإرسال"),
            "failed": ("Could not be submitted", "No se ha podido enviar", "N’a pas pu être envoyé", "Non è stato possibile inviarlo", "Konnte nicht gesendet werden", "Não foi possível enviar", "تعذّر الإرسال"),
            "pending": DECISION_PENDING,
        },
        content=f"""
{p("$tx_intro")}
#foreach($requestDetail in $requestDetails)
{subheading("${requestDetail.identityName}")}
#set($successDetails = $requestDetail.successDetails)
#if($successDetails && $successDetails.size() > 0)
<p style="margin:6px 0 4px 0;font-size:13px;font-weight:700;color:#1E7B4F;">$tx_submitted</p>
<ul style="margin:0 0 14px 0;padding:$emeaListPad;">#foreach($typeEntry in $objectTypeToPrettyPrint.entrySet())#set($type = $typeEntry.getKey())#set($prettyType = $typeEntry.getValue())#set($objectDetails = {{}})#set($objectDetails = ${{successDetails.get($type)}})#if($objectDetails.size() > 0)#foreach($requestedObjectDetail in $objectDetails)<li style="margin:0 0 4px 0;">$prettyType: <strong>${{requestedObjectDetail.objectName}}</strong>#if($requestedObjectDetail.startDate) · $tx_startsOn: $spTools.formatOffsetDateTimeForEmail($requestedObjectDetail.startDate)#end#if($requestedObjectDetail.removeDate) · $tx_endsOn: $spTools.formatOffsetDateTimeForEmail($requestedObjectDetail.removeDate)#end</li>#end#end#end</ul>
#end
#set($exclusionDetails = $requestDetail.exclusionDetails)
#if($exclusionDetails && $exclusionDetails.size() > 0)
<p style="margin:6px 0 4px 0;font-size:13px;font-weight:700;color:#B42318;">$tx_failed</p>
<ul style="margin:0 0 14px 0;padding:$emeaListPad;">#foreach($typeEntry in $objectTypeToPrettyPrint.entrySet())#set($type = $typeEntry.getKey())#set($prettyType = $typeEntry.getValue())#set($objectDetails = {{}})#set($objectDetails = ${{exclusionDetails.get($type)}})#if($objectDetails.size() > 0)#foreach($requestedObjectDetail in $objectDetails)<li style="margin:0 0 4px 0;">$prettyType: <strong>${{requestedObjectDetail.objectName}}</strong>#if($requestedObjectDetail.exclusionReason) – $requestedObjectDetail.exclusionReason#end</li>#end#end#end</ul>
#end
#end
{p("$tx_pending")}
""",
        sample={"requestDetails": "list:"},
    ),
    Rewrite(
        key="pending_access_request_cancelled",
        greet="$emailRecipientName",
        subject=(
            "An access request has been cancelled",
            "Se ha cancelado una solicitud de acceso",
            "Une demande d’accès a été annulée",
            "Una richiesta di accesso è stata annullata",
            "Eine Zugriffsanfrage wurde storniert",
            "Um pedido de acesso foi cancelado",
            "تم إلغاء طلب وصول",
        ),
        prelude="""
#set($emeaMine = false)#if($emailRecipientName == $requesterName)#set($emeaMine = true)#end
#set($emeaByOther = false)#if($cancelerName != $emailRecipientName)#set($emeaByOther = true)#end
""",
        strings={
            "introMine": (
                "Your pending access request has been cancelled.",
                "Tu solicitud de acceso pendiente se ha cancelado.",
                "Votre demande d’accès en attente a été annulée.",
                "La tua richiesta di accesso in sospeso è stata annullata.",
                "Ihre ausstehende Zugriffsanfrage wurde storniert.",
                "O seu pedido de acesso pendente foi cancelado.",
                "تم إلغاء طلب الوصول المعلّق الخاص بك.",
            ),
            "introOther": (
                "A pending access request has been cancelled.",
                "Se ha cancelado una solicitud de acceso pendiente.",
                "Une demande d’accès en attente a été annulée.",
                "Una richiesta di accesso in sospeso è stata annullata.",
                "Eine ausstehende Zugriffsanfrage wurde storniert.",
                "Um pedido de acesso pendente foi cancelado.",
                "تم إلغاء طلب وصول معلّق.",
            ),
            "cancelledBy": ("Cancelled by", "Cancelada por", "Annulée par", "Annullata da", "Storniert von", "Cancelado por", "ألغاه"),
            "reason": ("Reason for cancelling:", "Motivo de la cancelación:", "Motif de l’annulation :", "Motivo dell’annullamento:", "Grund für die Stornierung:", "Motivo do cancelamento:", "سبب الإلغاء:"),
            "contactCanceler": (
                "If you have any questions, contact ${cancelerName}.",
                "Si tienes alguna pregunta, ponte en contacto con ${cancelerName}.",
                "Pour toute question, contactez ${cancelerName}.",
                "Per qualsiasi domanda, contatta ${cancelerName}.",
                "Bei Fragen wenden Sie sich an ${cancelerName}.",
                "Se tiver alguma dúvida, contacte ${cancelerName}.",
                "إذا كانت لديك أي أسئلة، فتواصل مع ${cancelerName}.",
            ),
        },
        content=f"""
#if($emeaMine)
{p("$tx_introMine")}
#else
{p("$tx_introOther")}
#end
{details([("$tx_requestedFor", "$requestedForName", "$isRobo"), ("$tx_cancelledBy", "$cancelerName", "$emeaByOther")])}
{by_type()}
#if($cancelComment)
{p("$tx_reason")}
{quote("$cancelComment")}
#end
#if($emeaByOther)
{p("$tx_contactCanceler")}
#end
""",
        sample={**ITEMS_SAMPLE, "emailRecipientName": "Ana García", "cancelerName": "Marco Rossi", "cancelComment": "Duplicate request.", "requestedForName": "Ana García"},
    ),
    Rewrite(
        key="access_request_for_identity_with_multiple_accounts_failed",
        greet="${recipientName}",
        subject=(
            "Your request for ${requestItemName} could not be completed",
            "No se ha podido completar tu solicitud de ${requestItemName}",
            "Votre demande pour ${requestItemName} n’a pas pu aboutir",
            "Non è stato possibile completare la tua richiesta per ${requestItemName}",
            "Ihre Anfrage für ${requestItemName} konnte nicht abgeschlossen werden",
            "Não foi possível concluir o seu pedido de ${requestItemName}",
            "تعذّر إكمال طلبك لـ ${requestItemName}",
        ),
        strings={
            "intro": (
                "Your request for <strong>${requestItemName}</strong> could not be completed because you have more than one account on <strong>${sourceName}</strong>.",
                "No se ha podido completar tu solicitud de <strong>${requestItemName}</strong> porque tienes más de una cuenta en <strong>${sourceName}</strong>.",
                "Votre demande pour <strong>${requestItemName}</strong> n’a pas pu aboutir, car vous disposez de plusieurs comptes sur <strong>${sourceName}</strong>.",
                "Non è stato possibile completare la tua richiesta per <strong>${requestItemName}</strong> perché hai più di un account su <strong>${sourceName}</strong>.",
                "Ihre Anfrage für <strong>${requestItemName}</strong> konnte nicht abgeschlossen werden, da Sie mehr als ein Konto in <strong>${sourceName}</strong> haben.",
                "Não foi possível concluir o seu pedido de <strong>${requestItemName}</strong> porque tem mais do que uma conta em <strong>${sourceName}</strong>.",
                "تعذّر إكمال طلبك لـ <strong>${requestItemName}</strong> لأن لديك أكثر من حساب واحد على <strong>${sourceName}</strong>.",
            ),
        },
        content=f"""
{note("$tx_intro")}
{p("$tx_contactAdmin")}
""",
        sample={"recipientName": "Ana García", "requestItemName": "VPN Access", "sourceName": "Active Directory"},
    ),
    Rewrite(
        key="access_sunset_date_reminder",
        greet="${recipientName}",
        subject=(
            "Reminder: your access to ${accessItemName} ends on ${scheduledSunsetDate}",
            "Recordatorio: tu acceso a ${accessItemName} finaliza el ${scheduledSunsetDate}",
            "Rappel : votre accès à ${accessItemName} prend fin le ${scheduledSunsetDate}",
            "Promemoria: il tuo accesso a ${accessItemName} termina il ${scheduledSunsetDate}",
            "Erinnerung: Ihr Zugriff auf ${accessItemName} endet am ${scheduledSunsetDate}",
            "Lembrete: o seu acesso a ${accessItemName} termina em ${scheduledSunsetDate}",
            "تذكير: ينتهي وصولك إلى ${accessItemName} في ${scheduledSunsetDate}",
        ),
        strings={
            "intro": (
                "Your access to <strong>${accessItemName}</strong> (${accessItemType}) is scheduled to end on <strong>${scheduledSunsetDate}</strong>.",
                "Tu acceso a <strong>${accessItemName}</strong> (${accessItemType}) finalizará el <strong>${scheduledSunsetDate}</strong>.",
                "Votre accès à <strong>${accessItemName}</strong> (${accessItemType}) prendra fin le <strong>${scheduledSunsetDate}</strong>.",
                "Il tuo accesso a <strong>${accessItemName}</strong> (${accessItemType}) terminerà il <strong>${scheduledSunsetDate}</strong>.",
                "Ihr Zugriff auf <strong>${accessItemName}</strong> (${accessItemType}) endet am <strong>${scheduledSunsetDate}</strong>.",
                "O seu acesso a <strong>${accessItemName}</strong> (${accessItemType}) termina em <strong>${scheduledSunsetDate}</strong>.",
                "من المقرر أن ينتهي وصولك إلى <strong>${accessItemName}</strong> (${accessItemType}) في <strong>${scheduledSunsetDate}</strong>.",
            ),
            "extend": (
                "If you still need it, extend the access by changing its end date before then.",
                "Si todavía lo necesitas, amplía el acceso cambiando su fecha de finalización antes de ese día.",
                "Si vous en avez encore besoin, prolongez l’accès en modifiant sa date de fin avant cette échéance.",
                "Se ne hai ancora bisogno, estendi l’accesso modificandone la data di fine prima di quel giorno.",
                "Wenn Sie den Zugriff weiterhin benötigen, verlängern Sie ihn vorher, indem Sie das Enddatum ändern.",
                "Se ainda precisar, prolongue o acesso alterando a data de fim antes desse dia.",
                "إذا كنت لا تزال بحاجة إليه، فمدّد الوصول بتغيير تاريخ انتهائه قبل ذلك الموعد.",
            ),
        },
        content=f"""
{info("$tx_intro")}
{p("$tx_extend")}
{p("$tx_contactAdmin")}
""",
        sample={"recipientName": "Ana García", "accessItemName": "Finance Reporting", "accessItemType": "role", "scheduledSunsetDate": "Dec 31, 2026"},
    ),
    Rewrite(
        key="access_revoke_approval_reassignment",
        greet="${newOwnerName}",
        subject=(
            "Review needed: access removal for ${requestedForIdentityName}",
            "Revisión pendiente: retirada de acceso de ${requestedForIdentityName}",
            "Examen requis : retrait d’accès pour ${requestedForIdentityName}",
            "Revisione richiesta: rimozione dell’accesso per ${requestedForIdentityName}",
            "Prüfung erforderlich: Zugriffsentzug für ${requestedForIdentityName}",
            "Revisão necessária: remoção de acesso de ${requestedForIdentityName}",
            "مراجعة مطلوبة: إزالة وصول لـ ${requestedForIdentityName}",
        ),
        prelude=OBJECT_TYPE
        + """
#set($emeaCascade = false)#if($requestedObjectType == "Role" || $requestedObjectType == "AccessProfile")#set($emeaCascade = true)#end
""",
        strings={
            "intro": (
                "${previousOwnerName} has reassigned to you a request to remove <strong>${requestedObjectName}</strong> ($emeaType) from <strong>${requestedForIdentityName}</strong>.",
                "${previousOwnerName} te ha reasignado una solicitud para retirar <strong>${requestedObjectName}</strong> ($emeaType) a <strong>${requestedForIdentityName}</strong>.",
                "${previousOwnerName} vous a réattribué une demande de retrait de <strong>${requestedObjectName}</strong> ($emeaType) pour <strong>${requestedForIdentityName}</strong>.",
                "${previousOwnerName} ti ha riassegnato una richiesta di rimozione di <strong>${requestedObjectName}</strong> ($emeaType) per <strong>${requestedForIdentityName}</strong>.",
                "${previousOwnerName} hat Ihnen eine Anfrage zugewiesen, <strong>${requestedObjectName}</strong> ($emeaType) von <strong>${requestedForIdentityName}</strong> zu entfernen.",
                "${previousOwnerName} reatribuiu-lhe um pedido para remover <strong>${requestedObjectName}</strong> ($emeaType) a <strong>${requestedForIdentityName}</strong>.",
                "أعاد ${previousOwnerName} إليك إسناد طلب لإزالة <strong>${requestedObjectName}</strong> ($emeaType) من <strong>${requestedForIdentityName}</strong>.",
            ),
            "reason": ("Reason for reassignment:", "Motivo de la reasignación:", "Motif de la réattribution :", "Motivo della riassegnazione:", "Grund für die Neuzuweisung:", "Motivo da reatribuição:", "سبب إعادة الإسناد:"),
            "lose": (
                "If you approve, ${requestedForIdentityName} will lose this access.",
                "Si la apruebas, ${requestedForIdentityName} perderá este acceso.",
                "Si vous l’approuvez, ${requestedForIdentityName} perdra cet accès.",
                "Se la approvi, ${requestedForIdentityName} perderà questo accesso.",
                "Wenn Sie genehmigen, verliert ${requestedForIdentityName} diesen Zugriff.",
                "Se aprovar, ${requestedForIdentityName} perderá este acesso.",
                "إذا وافقت، فسيفقد ${requestedForIdentityName} هذا الوصول.",
            ),
            "loseAll": (
                "If you approve, ${requestedForIdentityName} will lose this access and all its entitlements.",
                "Si la apruebas, ${requestedForIdentityName} perderá este acceso y todos sus derechos.",
                "Si vous l’approuvez, ${requestedForIdentityName} perdra cet accès et tous les droits d’accès associés.",
                "Se la approvi, ${requestedForIdentityName} perderà questo accesso e tutte le autorizzazioni associate.",
                "Wenn Sie genehmigen, verliert ${requestedForIdentityName} diesen Zugriff und alle zugehörigen Berechtigungen.",
                "Se aprovar, ${requestedForIdentityName} perderá este acesso e todos os direitos associados.",
                "إذا وافقت، فسيفقد ${requestedForIdentityName} هذا الوصول وجميع استحقاقاته.",
            ),
        },
        content=f"""
{p("$tx_intro")}
#if($commentText)
{p("$tx_reason")}
{quote("${commentText}")}
#end
#if($emeaCascade)
{note("$tx_loseAll")}
#else
{note("$tx_lose")}
#end
""",
        sample={"newOwnerName": "Lena Müller", "previousOwnerName": "Marco Rossi"},
    ),
    Rewrite(
        key="access_revoke_request_decision_email_for_requested-for_identity",
        greet="${user.name}",
        subject=(
            "#if($approved)Approved#{else}Denied#end: request to remove your access",
            "#if($approved)Aprobada#{else}Denegada#end: solicitud para retirar tu acceso",
            "#if($approved)Approuvée#{else}Refusée#end : demande de retrait de votre accès",
            "#if($approved)Approvata#{else}Rifiutata#end: richiesta di rimozione del tuo accesso",
            "#if($approved)Genehmigt#{else}Abgelehnt#end: Anfrage zum Entzug Ihres Zugriffs",
            "#if($approved)Aprovado#{else}Recusado#end: pedido de remoção do seu acesso",
            "#if($approved)تمت الموافقة#{else}تم الرفض#end: طلب إزالة وصولك",
        ),
        prelude=OBJECT_TYPE + STATUS,
        strings={
            "intro": (
                "${requesterName}’s request to remove your access to <strong>${requestedObjectName}</strong> ($emeaType) has been $emeaStatusHtml.",
                "La solicitud de ${requesterName} para retirar tu acceso a <strong>${requestedObjectName}</strong> ($emeaType) ha sido $emeaStatusHtml.",
                "La demande de ${requesterName} visant à retirer votre accès à <strong>${requestedObjectName}</strong> ($emeaType) a été $emeaStatusHtml.",
                "La richiesta di ${requesterName} di rimuovere il tuo accesso a <strong>${requestedObjectName}</strong> ($emeaType) è stata $emeaStatusHtml.",
                "Die Anfrage von ${requesterName}, Ihren Zugriff auf <strong>${requestedObjectName}</strong> ($emeaType) zu entziehen, wurde $emeaStatusHtml.",
                "O pedido de ${requesterName} para remover o seu acesso a <strong>${requestedObjectName}</strong> ($emeaType) foi $emeaStatusHtml.",
                "طلب ${requesterName} لإزالة وصولك إلى <strong>${requestedObjectName}</strong> ($emeaType) $emeaStatusHtml.",
            ),
            "contactRequester": CONTACT_REQUESTER,
        },
        content=f"""
{p("$tx_intro")}
#if($removeDate)
{details([("$tx_endsOn", "${removeDate}")])}
#end
{p("$tx_contactRequester")}
""",
    ),
    Rewrite(
        key="access_revoke_request_decision_for_requester",
        greet="${user.name}",
        subject=(
            "#if($approved)Approved#{else}Denied#end: your request to remove ${requestedObjectName}",
            "#if($approved)Aprobada#{else}Denegada#end: tu solicitud para retirar ${requestedObjectName}",
            "#if($approved)Approuvée#{else}Refusée#end : votre demande de retrait de ${requestedObjectName}",
            "#if($approved)Approvata#{else}Rifiutata#end: la tua richiesta di rimozione di ${requestedObjectName}",
            "#if($approved)Genehmigt#{else}Abgelehnt#end: Ihre Anfrage zum Entzug von ${requestedObjectName}",
            "#if($approved)Aprovado#{else}Recusado#end: o seu pedido de remoção de ${requestedObjectName}",
            "#if($approved)تمت الموافقة#{else}تم الرفض#end: طلبك لإزالة ${requestedObjectName}",
        ),
        prelude=OBJECT_TYPE + STATUS,
        strings={
            "intro": (
                "Your request to remove <strong>${requestedObjectName}</strong> ($emeaType) from <strong>${requestedForIdentityName}</strong> has been $emeaStatusHtml.",
                "Tu solicitud para retirar <strong>${requestedObjectName}</strong> ($emeaType) a <strong>${requestedForIdentityName}</strong> ha sido $emeaStatusHtml.",
                "Votre demande de retrait de <strong>${requestedObjectName}</strong> ($emeaType) pour <strong>${requestedForIdentityName}</strong> a été $emeaStatusHtml.",
                "La tua richiesta di rimuovere <strong>${requestedObjectName}</strong> ($emeaType) a <strong>${requestedForIdentityName}</strong> è stata $emeaStatusHtml.",
                "Ihre Anfrage, <strong>${requestedObjectName}</strong> ($emeaType) von <strong>${requestedForIdentityName}</strong> zu entfernen, wurde $emeaStatusHtml.",
                "O seu pedido para remover <strong>${requestedObjectName}</strong> ($emeaType) a <strong>${requestedForIdentityName}</strong> foi $emeaStatusHtml.",
                "طلبك لإزالة <strong>${requestedObjectName}</strong> ($emeaType) من <strong>${requestedForIdentityName}</strong> $emeaStatusHtml.",
            ),
            "removedOn": (
                "The access will be removed on ${removeDate}.",
                "El acceso se retirará el ${removeDate}.",
                "L’accès sera retiré le ${removeDate}.",
                "L’accesso verrà rimosso il ${removeDate}.",
                "Der Zugriff wird am ${removeDate} entzogen.",
                "O acesso será removido em ${removeDate}.",
                "ستتم إزالة الوصول في ${removeDate}.",
            ),
            "removedSoon": (
                "The access will be removed shortly, after additional processing.",
                "El acceso se retirará en breve, tras un procesamiento adicional.",
                "L’accès sera retiré prochainement, après un traitement complémentaire.",
                "L’accesso verrà rimosso a breve, dopo un’ulteriore elaborazione.",
                "Der Zugriff wird nach weiterer Verarbeitung in Kürze entzogen.",
                "O acesso será removido em breve, após processamento adicional.",
                "ستتم إزالة الوصول قريبًا، بعد معالجة إضافية.",
            ),
            "commentFrom": COMMENT_FROM,
            "contactRejecter": CONTACT_REJECTER,
        },
        content=f"""
{p("$tx_intro")}
#if($approved)
#if($removeDate){info("$tx_removedOn")}#else{info("$tx_removedSoon")}#end
#else
#if($reviewerComment)
{p("$tx_commentFrom")}
{quote("$reviewerComment")}
#end
{p("$tx_contactRejecter")}
#end
""",
    ),
    Rewrite(
        key="access_revoke_request_reviewer",
        greet="${user.name}",
        subject=(
            "Review needed: access removal for ${requestedForIdentityName}",
            "Revisión pendiente: retirada de acceso de ${requestedForIdentityName}",
            "Examen requis : retrait d’accès pour ${requestedForIdentityName}",
            "Revisione richiesta: rimozione dell’accesso per ${requestedForIdentityName}",
            "Prüfung erforderlich: Zugriffsentzug für ${requestedForIdentityName}",
            "Revisão necessária: remoção de acesso de ${requestedForIdentityName}",
            "مراجعة مطلوبة: إزالة وصول لـ ${requestedForIdentityName}",
        ),
        prelude=OBJECT_TYPE
        + """
#set($emeaCascade = false)#if($requestedObjectType == "Role" || $requestedObjectType == "AccessProfile")#set($emeaCascade = true)#end
""",
        strings={
            "intro": (
                "$requesterName has requested to remove <strong>$requestedObjectName</strong> ($emeaType) from <strong>$requestedForIdentityName</strong>. Please review the request.",
                "$requesterName ha solicitado retirar <strong>$requestedObjectName</strong> ($emeaType) a <strong>$requestedForIdentityName</strong>. Revisa la solicitud.",
                "$requesterName a demandé le retrait de <strong>$requestedObjectName</strong> ($emeaType) pour <strong>$requestedForIdentityName</strong>. Veuillez examiner la demande.",
                "$requesterName ha richiesto di rimuovere <strong>$requestedObjectName</strong> ($emeaType) a <strong>$requestedForIdentityName</strong>. Esamina la richiesta.",
                "$requesterName hat beantragt, <strong>$requestedObjectName</strong> ($emeaType) von <strong>$requestedForIdentityName</strong> zu entfernen. Bitte prüfen Sie die Anfrage.",
                "$requesterName pediu para remover <strong>$requestedObjectName</strong> ($emeaType) a <strong>$requestedForIdentityName</strong>. Reveja o pedido.",
                "طلب $requesterName إزالة <strong>$requestedObjectName</strong> ($emeaType) من <strong>$requestedForIdentityName</strong>. يُرجى مراجعة الطلب.",
            ),
            "reason": (
                "Reason given by $requesterName:",
                "Motivo indicado por $requesterName:",
                "Motif indiqué par $requesterName :",
                "Motivazione fornita da $requesterName:",
                "Begründung von $requesterName:",
                "Motivo indicado por $requesterName:",
                "السبب الذي قدّمه $requesterName:",
            ),
            "lose": (
                "If approved, $requestedForIdentityName will lose this access.",
                "Si se aprueba, $requestedForIdentityName perderá este acceso.",
                "En cas d’approbation, $requestedForIdentityName perdra cet accès.",
                "Se approvata, $requestedForIdentityName perderà questo accesso.",
                "Bei Genehmigung verliert $requestedForIdentityName diesen Zugriff.",
                "Se for aprovado, $requestedForIdentityName perderá este acesso.",
                "في حال الموافقة، سيفقد $requestedForIdentityName هذا الوصول.",
            ),
            "loseAll": (
                "If approved, $requestedForIdentityName will lose this access and all its entitlements.",
                "Si se aprueba, $requestedForIdentityName perderá este acceso y todos sus derechos.",
                "En cas d’approbation, $requestedForIdentityName perdra cet accès et tous les droits d’accès associés.",
                "Se approvata, $requestedForIdentityName perderà questo accesso e tutte le autorizzazioni associate.",
                "Bei Genehmigung verliert $requestedForIdentityName diesen Zugriff und alle zugehörigen Berechtigungen.",
                "Se for aprovado, $requestedForIdentityName perderá este acesso e todos os direitos associados.",
                "في حال الموافقة، سيفقد $requestedForIdentityName هذا الوصول وجميع استحقاقاته.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{details([("$tx_requestedBy", "$requesterName"), ("$tx_requestedFor", "$requestedForIdentityName"), ("$tx_endsOn", "$removeDate", "$removeDate")])}
#if($requesterComments)
{p("$tx_reason")}
{quote("$requesterComments")}
#end
#if($emeaCascade)
{note("$tx_loseAll")}
#else
{note("$tx_lose")}
#end
""",
    ),
    Rewrite(
        key="access_revoke_request_submitted_email_for_requested-for_identity",
        greet="${requestedForIdentityName}",
        subject=(
            "$requesterName has requested to remove your access",
            "$requesterName ha solicitado retirar tu acceso",
            "$requesterName a demandé le retrait de votre accès",
            "$requesterName ha richiesto di rimuovere il tuo accesso",
            "$requesterName hat den Entzug Ihres Zugriffs beantragt",
            "$requesterName pediu a remoção do seu acesso",
            "طلب $requesterName إزالة وصولك",
        ),
        strings={
            "intro": (
                "$requesterName has requested to remove your access to the items below.",
                "$requesterName ha solicitado retirar tu acceso a los elementos siguientes.",
                "$requesterName a demandé le retrait de votre accès aux éléments ci-dessous.",
                "$requesterName ha richiesto di rimuovere il tuo accesso agli elementi seguenti.",
                "$requesterName hat beantragt, Ihren Zugriff auf die folgenden Elemente zu entziehen.",
                "$requesterName pediu para remover o seu acesso aos itens abaixo.",
                "طلب $requesterName إزالة وصولك إلى العناصر أدناه.",
            ),
            "pending": DECISION_PENDING,
            "contactRequester": CONTACT_REQUESTER,
        },
        content=f"""
{p("$tx_intro")}
{by_type(with_start=False)}
{p("$tx_pending")}
{p("$tx_contactRequester")}
""",
        sample=ITEMS_SAMPLE,
    ),
    Rewrite(
        key="access_revoke_request_submitted_email_for_requester_identity",
        greet="${requesterName}",
        subject=(
            "Your request to remove access was submitted",
            "Tu solicitud de retirada de acceso se ha enviado",
            "Votre demande de retrait d’accès a été envoyée",
            "La tua richiesta di rimozione dell’accesso è stata inviata",
            "Ihre Anfrage zum Zugriffsentzug wurde gesendet",
            "O seu pedido de remoção de acesso foi enviado",
            "تم إرسال طلبك لإزالة الوصول",
        ),
        strings={
            "intro": (
                "Your request to remove the access below was submitted successfully.",
                "Tu solicitud para retirar el acceso siguiente se ha enviado correctamente.",
                "Votre demande de retrait de l’accès ci-dessous a bien été envoyée.",
                "La tua richiesta di rimuovere l’accesso seguente è stata inviata correttamente.",
                "Ihre Anfrage zum Entzug des folgenden Zugriffs wurde erfolgreich gesendet.",
                "O seu pedido para remover o acesso abaixo foi enviado com êxito.",
                "تم إرسال طلبك لإزالة الوصول أدناه بنجاح.",
            ),
            "people": ("Requested for:", "Solicitado para:", "Demandé pour :", "Richiesto per:", "Angefordert für:", "Pedido para:", "مطلوب لـ:"),
            "notified": (
                "The people concerned have also been notified.",
                "También se ha notificado a las personas afectadas.",
                "Les personnes concernées ont également été informées.",
                "Anche le persone interessate sono state informate.",
                "Die betroffenen Personen wurden ebenfalls benachrichtigt.",
                "As pessoas abrangidas também foram notificadas.",
                "تم إعلام الأشخاص المعنيين أيضًا.",
            ),
            "pending": DECISION_PENDING,
        },
        content=f"""
{p("$tx_intro")}
#if($requestedForIdentityNames && $requestedForIdentityNames.size() > 0)
{subheading("$tx_people")}
{bullets("#foreach($name in $requestedForIdentityNames)" + li("$name") + "#end")}
#end
{by_type(with_start=False)}
{p("$tx_pending")}
#if($requestedForIdentityNames && $requestedForIdentityNames.size() > 0)
{p("$tx_notified")}
#end
{p("$tx_contactAdmin")}
""",
        sample={**ITEMS_SAMPLE, "requestedForIdentityNames": "list:Ana García,João Silva"},
    ),
]
