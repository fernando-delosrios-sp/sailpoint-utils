"""Approvals, certifications, work items, Just-In-Time access, account requests and SoD.

Most of these are version 2 templates (`$__recipient`, `$__global`); certifications, task
reassignment and work item forwarding are version 1.
"""

from build_templates import LANGUAGES, Rewrite, button, details, info, note, p, quote

PN2 = "$__global.productName"
URL2 = "$__global.productUrl"
R2 = "${__recipient.name}"

# --- approvals -------------------------------------------------------------

# `$emeaWho`: "onBehalf" (submitted for the recipient by someone else), "you", or "other" (`$emeaBy` = submitter).
# `$emeaMine`: the recipient is the requester or the requestee.
WHO = """
#set($emeaMine = false)#if($requestee.identityID == $__recipient.id || $requester.identityID == $__recipient.id)#set($emeaMine = true)#end
#if($requestee.name && $requestee.name != '' && $requestee.identityID == $__recipient.id)#set($emeaWho = "onBehalf")
#elseif($requestee.name && $requestee.name != '')#set($emeaWho = "other")#set($emeaBy = "$requestee.name")
#elseif($requester.identityID == $__recipient.id)#set($emeaWho = "you")
#else#set($emeaWho = "other")#set($emeaBy = "$requester.name")#end
"""

APPROVER_LINK = f"{URL2}/ui/d/$approverPath"
REQUESTER_LINK = f"{URL2}/ui/d/$requesterPath"

SUBMITTED_ROWS = [
    ("$tx_requestedBy", "$requester.name"),
    ("$tx_requestedFor", "$requestee.name", "$requestee.name && $requestee.name != ''"),
]


def who_content(strings_prefix: str) -> str:
    return f"""
#if($emeaWho == "onBehalf")
{p(f"$tx_{strings_prefix}OnBehalf")}
#elseif($emeaWho == "you")
{p(f"$tx_{strings_prefix}You")}
#else
{p(f"$tx_{strings_prefix}Other")}
#end"""


def mine_button() -> str:
    return f"""
#if($emeaMine)
{button(REQUESTER_LINK, "$tx_viewRequests")}
#else
{button(APPROVER_LINK, "$tx_reviewNow")}
#end"""


def status_inline(values: tuple[str, str, str, str]) -> str:
    """Velocity picking approved/rejected/cancelled words (else the raw status) from `$approvalStatus`."""
    approved, rejected, cancelled, _ = values
    return (
        '#set($eSt="$!approvalStatus")#set($eSt=$eSt.toLowerCase())'
        f'#if($eSt=="approved"){approved}#elseif($eSt=="rejected"||$eSt=="denied"){rejected}'
        f'#elseif($eSt.startsWith("cancel")){cancelled}#{{else}}$eSt#end'
    )


_STATUS_WORDS = {
    "en": ("approved", "rejected", "cancelled", ""),
    "es": ("aprobada", "rechazada", "cancelada", ""),
    "fr": ("approuvée", "refusée", "annulée", ""),
    "it": ("approvata", "rifiutata", "annullata", ""),
    "de": ("genehmigt", "abgelehnt", "storniert", ""),
    "pt": ("aprovado", "rejeitado", "cancelado", ""),
    "ar": ("تمت الموافقة عليه", "تم رفضه", "تم إلغاؤه", ""),
}

APPROVAL_STATUS_PRELUDE = f"""
#set($emeaSt = "$!approvalStatus")#set($emeaSt = $emeaSt.toLowerCase())
#if($emeaSt == "approved")#set($emeaStatusHtml = "<strong>$tx_statusApproved</strong>")
#elseif($emeaSt == "rejected" || $emeaSt == "denied")#set($emeaStatusHtml = "<strong>$tx_statusDenied</strong>")
#elseif($emeaSt == "cancelled" || $emeaSt == "canceled")#set($emeaStatusHtml = "<strong>$tx_statusCancelled</strong>")
#else#set($emeaStatusHtml = "<strong>$emeaSt</strong>")#end
"""

CONTACT_OWNER = (
    "If you have any questions, contact ${ownerName}.",
    "Si tienes alguna pregunta, ponte en contacto con ${ownerName}.",
    "Pour toute question, contactez ${ownerName}.",
    "Per qualsiasi domanda, contatta ${ownerName}.",
    "Bei Fragen wenden Sie sich an ${ownerName}.",
    "Se tiver alguma dúvida, contacte ${ownerName}.",
    "إذا كانت لديك أي أسئلة، فتواصل مع ${ownerName}.",
)

MANAGE_ACCESS = ("Manage access", "Gestionar acceso", "Gérer l’accès", "Gestisci accesso", "Zugriff verwalten", "Gerir acesso", "إدارة الوصول")

JIT_NOTE = (
    "<strong>This entitlement must be activated before each use.</strong> Go to MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Este derecho debe activarse antes de cada uso.</strong> Ve a MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Ce droit d’accès doit être activé avant chaque utilisation.</strong> Accédez à MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Questa autorizzazione deve essere attivata prima di ogni utilizzo.</strong> Vai a MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Diese Berechtigung muss vor jeder Nutzung aktiviert werden.</strong> Öffnen Sie MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>Este direito de acesso tem de ser ativado antes de cada utilização.</strong> Aceda a MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
    "<strong>يجب تفعيل هذا الاستحقاق قبل كل استخدام.</strong> انتقل إلى MySailPoint &gt; Launchpad &gt; Just-In-Time Access.",
)

APPLICATION = ("Application", "Aplicación", "Application", "Applicazione", "Anwendung", "Aplicação", "التطبيق")
ENTITLEMENT = ("Entitlement", "Derecho", "Droit d’accès", "Autorizzazione", "Berechtigung", "Direito de acesso", "الاستحقاق")

# --- certifications (version 1) ---------------------------------------------

CERT_PRELUDE = """
#set($emeaCampaign = "$certification.certificationGroups.get(0).name")
#if($certification.expiration)#set($emeaDue = "$spTools.formatDate($certification.expiration,3,0)")#end
#set($emeaCertUrl = "$identityNowUrl/ui/d/certifications-review/certification/${certification.id}")
"""

DUE_BY = ("Due by", "Fecha límite", "À terminer avant le", "Scadenza", "Fällig bis", "Prazo", "الموعد النهائي")
CERTIFICATION = ("Certification", "Certificación", "Certification", "Certificazione", "Zertifizierung", "Certificação", "الاعتماد")
REVIEW_CERT = ("Review certification", "Revisar certificación", "Examiner la certification", "Esamina certificazione", "Zertifizierung prüfen", "Rever certificação", "مراجعة الاعتماد")

# --- work reassignment (version 2) ------------------------------------------


def reassignment_prelude(prefix: str) -> str:
    return f"""
#if($emeaLang == "en")#set($emeaDatePattern = "EEEE, MMMM d, yyyy")#elseif($emeaLang == "de")#set($emeaDatePattern = "dd.MM.yyyy")#else#set($emeaDatePattern = "dd/MM/yyyy")#end
#set($_startDate = $__dateTool.toDate("yyyy-MM-dd'T'HH:mm:ss", ${{{prefix}startDate}}))
#set($emeaStart = $__dateTool.format($emeaDatePattern, $_startDate))
#set($emeaHasEnd = false)
#if(${{{prefix}endDate}} && ${{{prefix}endDate}} != "0001-01-01T00:00:00Z")#set($emeaHasEnd = true)#set($_endDate = $__dateTool.toDate("yyyy-MM-dd'T'HH:mm:ss", ${{{prefix}endDate}}))#set($emeaEnd = $__dateTool.format($emeaDatePattern, $_endDate))#end
"""


def reassignment_strings(prefix: str) -> dict:
    v = lambda name: "${" + prefix + name + "}"  # noqa: E731
    return {
        "intro": (
            f"{v('modifiedByName')} has set up automatic reassignment of <strong>{v('configType')}</strong> from <strong>{v('reassignedFromName')}</strong> to <strong>{v('reassignedToName')}</strong>.",
            f"{v('modifiedByName')} ha configurado la reasignación automática de <strong>{v('configType')}</strong> de <strong>{v('reassignedFromName')}</strong> a <strong>{v('reassignedToName')}</strong>.",
            f"{v('modifiedByName')} a configuré la réattribution automatique de <strong>{v('configType')}</strong> de <strong>{v('reassignedFromName')}</strong> à <strong>{v('reassignedToName')}</strong>.",
            f"{v('modifiedByName')} ha configurato la riassegnazione automatica di <strong>{v('configType')}</strong> da <strong>{v('reassignedFromName')}</strong> a <strong>{v('reassignedToName')}</strong>.",
            f"{v('modifiedByName')} hat die automatische Neuzuweisung von <strong>{v('configType')}</strong> von <strong>{v('reassignedFromName')}</strong> an <strong>{v('reassignedToName')}</strong> eingerichtet.",
            f"{v('modifiedByName')} configurou a reatribuição automática de <strong>{v('configType')}</strong> de <strong>{v('reassignedFromName')}</strong> para <strong>{v('reassignedToName')}</strong>.",
            f"أعدّ {v('modifiedByName')} إعادة إسناد تلقائية لـ <strong>{v('configType')}</strong> من <strong>{v('reassignedFromName')}</strong> إلى <strong>{v('reassignedToName')}</strong>.",
        ),
        "noEnd": ("No end date", "Sin fecha de finalización", "Aucune date de fin", "Nessuna data di fine", "Kein Enddatum", "Sem data de fim", "بدون تاريخ انتهاء"),
    }


REASSIGNMENT_CONTENT = f"""
{p("$tx_intro")}
#if($emeaHasEnd)
{details([("$tx_startsOn", "$emeaStart"), ("$tx_endsOn", "$emeaEnd")])}
#else
{details([("$tx_startsOn", "$emeaStart"), ("$tx_endsOn", "$tx_noEnd")])}
#end
"""

# --- account requests (version 2) --------------------------------------------

ACCOUNT_ROWS = [
    ("$tx_operation", "$data.operationType"),
    ("$tx_account", "$data.accountName"),
    ("$tx_source", "$data.sourceName"),
]

ACCOUNT_LABELS = {
    "operation": ("Operation", "Operación", "Opération", "Operazione", "Vorgang", "Operação", "العملية"),
    "account": ("Account", "Cuenta", "Compte", "Account", "Konto", "Conta", "الحساب"),
    "source": ("Source", "Origen", "Source", "Origine", "Quelle", "Origem", "المصدر"),
}

ACCOUNT_SAMPLE = {
    "data.sourceName": "Active Directory",
    "data.operationType": "Delete",
    "data.accountName": "svc-reporting",
    "data.requesterName": "Ana García",
    "data.failureReason": "Insufficient permissions on the target OU.",
}


TEMPLATES = [
    # ---------------------------------------------------------------- approvals
    Rewrite(
        key="approval_commented_notification",
        greet=R2,
        subject=(
            "New comment on the approval request for $approvalName",
            "Nuevo comentario en la solicitud de aprobación de $approvalName",
            "Nouveau commentaire sur la demande d’approbation de $approvalName",
            "Nuovo commento sulla richiesta di approvazione di $approvalName",
            "Neuer Kommentar zur Genehmigungsanfrage für $approvalName",
            "Novo comentário no pedido de aprovação de $approvalName",
            "تعليق جديد على طلب الموافقة الخاص بـ $approvalName",
        ),
        prelude=WHO,
        strings={
            "introOnBehalf": (
                "There is a new comment on the approval request for <strong>$approvalName</strong>, submitted on your behalf by $requester.name.",
                "Hay un comentario nuevo en la solicitud de aprobación de <strong>$approvalName</strong>, enviada en tu nombre por $requester.name.",
                "Un nouveau commentaire a été ajouté à la demande d’approbation de <strong>$approvalName</strong>, envoyée en votre nom par $requester.name.",
                "C’è un nuovo commento sulla richiesta di approvazione di <strong>$approvalName</strong>, inviata per tuo conto da $requester.name.",
                "Zur Genehmigungsanfrage für <strong>$approvalName</strong>, die $requester.name in Ihrem Namen gestellt hat, gibt es einen neuen Kommentar.",
                "Há um novo comentário no pedido de aprovação de <strong>$approvalName</strong>, enviado em seu nome por $requester.name.",
                "يوجد تعليق جديد على طلب الموافقة الخاص بـ <strong>$approvalName</strong>، الذي قدّمه $requester.name نيابةً عنك.",
            ),
            "introYou": (
                "There is a new comment on your approval request for <strong>$approvalName</strong>.",
                "Hay un comentario nuevo en tu solicitud de aprobación de <strong>$approvalName</strong>.",
                "Un nouveau commentaire a été ajouté à votre demande d’approbation de <strong>$approvalName</strong>.",
                "C’è un nuovo commento sulla tua richiesta di approvazione di <strong>$approvalName</strong>.",
                "Zu Ihrer Genehmigungsanfrage für <strong>$approvalName</strong> gibt es einen neuen Kommentar.",
                "Há um novo comentário no seu pedido de aprovação de <strong>$approvalName</strong>.",
                "يوجد تعليق جديد على طلب الموافقة الخاص بك لـ <strong>$approvalName</strong>.",
            ),
            "introOther": (
                "There is a new comment on the approval request for <strong>$approvalName</strong>, submitted by $emeaBy.",
                "Hay un comentario nuevo en la solicitud de aprobación de <strong>$approvalName</strong>, enviada por $emeaBy.",
                "Un nouveau commentaire a été ajouté à la demande d’approbation de <strong>$approvalName</strong>, envoyée par $emeaBy.",
                "C’è un nuovo commento sulla richiesta di approvazione di <strong>$approvalName</strong>, inviata da $emeaBy.",
                "Zur Genehmigungsanfrage für <strong>$approvalName</strong> von $emeaBy gibt es einen neuen Kommentar.",
                "Há um novo comentário no pedido de aprovação de <strong>$approvalName</strong>, enviado por $emeaBy.",
                "يوجد تعليق جديد على طلب الموافقة الخاص بـ <strong>$approvalName</strong>، الذي قدّمه $emeaBy.",
            ),
        },
        content=who_content("intro") + mine_button(),
        sample={"requester.name": "Marco Rossi", "requester.identityID": "x1"},
    ),
    Rewrite(
        key="approval_completed_notification",
        greet=R2,
        subject=tuple(
            {
                "en": "Your approval request for $approvalName has been ",
                "es": "Tu solicitud de aprobación de $approvalName ha sido ",
                "fr": "Votre demande d’approbation de $approvalName a été ",
                "it": "La tua richiesta di approvazione di $approvalName è stata ",
                "de": "Ihre Genehmigungsanfrage für $approvalName wurde ",
                "pt": "O seu pedido de aprovação de $approvalName foi ",
                "ar": "طلب الموافقة الخاص بك لـ $approvalName ",
            }[lang]
            + status_inline(_STATUS_WORDS[lang])
            for lang in LANGUAGES
        ),
        prelude="""
#set($emeaOnBehalf = false)#if($requestee.name && $requestee.name != '' && $requestee.identityID == $__recipient.id)#set($emeaOnBehalf = true)#end
""" + APPROVAL_STATUS_PRELUDE,
        strings={
            "introOnBehalf": (
                "The approval request for <strong>$approvalName</strong>, submitted on your behalf by $requester.name, has been $emeaStatusHtml.",
                "La solicitud de aprobación de <strong>$approvalName</strong>, enviada en tu nombre por $requester.name, ha sido $emeaStatusHtml.",
                "La demande d’approbation de <strong>$approvalName</strong>, envoyée en votre nom par $requester.name, a été $emeaStatusHtml.",
                "La richiesta di approvazione di <strong>$approvalName</strong>, inviata per tuo conto da $requester.name, è stata $emeaStatusHtml.",
                "Die Genehmigungsanfrage für <strong>$approvalName</strong>, die $requester.name in Ihrem Namen gestellt hat, wurde $emeaStatusHtml.",
                "O pedido de aprovação de <strong>$approvalName</strong>, enviado em seu nome por $requester.name, foi $emeaStatusHtml.",
                "طلب الموافقة الخاص بـ <strong>$approvalName</strong>، الذي قدّمه $requester.name نيابةً عنك، $emeaStatusHtml.",
            ),
            "introYou": (
                "Your approval request for <strong>$approvalName</strong> has been $emeaStatusHtml.",
                "Tu solicitud de aprobación de <strong>$approvalName</strong> ha sido $emeaStatusHtml.",
                "Votre demande d’approbation de <strong>$approvalName</strong> a été $emeaStatusHtml.",
                "La tua richiesta di approvazione di <strong>$approvalName</strong> è stata $emeaStatusHtml.",
                "Ihre Genehmigungsanfrage für <strong>$approvalName</strong> wurde $emeaStatusHtml.",
                "O seu pedido de aprovação de <strong>$approvalName</strong> foi $emeaStatusHtml.",
                "طلب الموافقة الخاص بك لـ <strong>$approvalName</strong> $emeaStatusHtml.",
            ),
        },
        content=f"""
#if($emeaOnBehalf)
{p("$tx_introOnBehalf")}
#else
{p("$tx_introYou")}
#end
{button(REQUESTER_LINK, "$tx_viewRequests")}
""",
        sample={"approvalStatus": "APPROVED", "requester.name": "Marco Rossi"},
    ),
    Rewrite(
        key="approval_request_escalation_approver",
        greet=R2,
        subject=(
            "#if($previousApprover.identityID == $__recipient.id)An approval request has been escalated from you#{else}An approval request has been escalated to you for review#end",
            "#if($previousApprover.identityID == $__recipient.id)Se ha escalado una solicitud de aprobación que tenías asignada#{else}Se te ha escalado una solicitud de aprobación para que la revises#end",
            "#if($previousApprover.identityID == $__recipient.id)Une demande d’approbation qui vous était attribuée a été remontée#{else}Une demande d’approbation vous a été remontée pour examen#end",
            "#if($previousApprover.identityID == $__recipient.id)Una richiesta di approvazione a te assegnata è stata inoltrata a un altro approvatore#{else}Ti è stata inoltrata una richiesta di approvazione da esaminare#end",
            "#if($previousApprover.identityID == $__recipient.id)Eine Ihnen zugewiesene Genehmigungsanfrage wurde eskaliert#{else}Eine Genehmigungsanfrage wurde zur Prüfung an Sie eskaliert#end",
            "#if($previousApprover.identityID == $__recipient.id)Um pedido de aprovação que lhe estava atribuído foi escalado#{else}Um pedido de aprovação foi-lhe escalado para revisão#end",
            "#if($previousApprover.identityID == $__recipient.id)تم تصعيد طلب موافقة منك#{else}تم تصعيد طلب موافقة إليك لمراجعته#end",
        ),
        strings={
            "fromYou": (
                "The approval request for <strong>$approvalName</strong> has been escalated from you to $escalatedApprover.name, because no action was taken for $escalationDelay.",
                "La solicitud de aprobación de <strong>$approvalName</strong> se ha escalado a $escalatedApprover.name porque no se ha realizado ninguna acción durante $escalationDelay.",
                "La demande d’approbation de <strong>$approvalName</strong> a été remontée à $escalatedApprover.name, car aucune action n’a été effectuée pendant $escalationDelay.",
                "La richiesta di approvazione di <strong>$approvalName</strong> è stata inoltrata a $escalatedApprover.name perché non è stata intrapresa alcuna azione per $escalationDelay.",
                "Die Genehmigungsanfrage für <strong>$approvalName</strong> wurde an $escalatedApprover.name eskaliert, da $escalationDelay lang keine Aktion erfolgt ist.",
                "O pedido de aprovação de <strong>$approvalName</strong> foi escalado para $escalatedApprover.name porque não foi tomada nenhuma ação durante $escalationDelay.",
                "تم تصعيد طلب الموافقة الخاص بـ <strong>$approvalName</strong> منك إلى $escalatedApprover.name، لعدم اتخاذ أي إجراء خلال $escalationDelay.",
            ),
            "toYou": (
                "The approval request for <strong>$approvalName</strong> has been escalated to you, because the previous approver did not act on it for $escalationDelay.",
                "Se te ha escalado la solicitud de aprobación de <strong>$approvalName</strong> porque el aprobador anterior no ha actuado durante $escalationDelay.",
                "La demande d’approbation de <strong>$approvalName</strong> vous a été remontée, car l’approbateur précédent n’a effectué aucune action pendant $escalationDelay.",
                "Ti è stata inoltrata la richiesta di approvazione di <strong>$approvalName</strong> perché l’approvatore precedente non è intervenuto per $escalationDelay.",
                "Die Genehmigungsanfrage für <strong>$approvalName</strong> wurde an Sie eskaliert, da die vorherige genehmigende Person $escalationDelay lang nicht reagiert hat.",
                "O pedido de aprovação de <strong>$approvalName</strong> foi-lhe escalado porque o aprovador anterior não tomou nenhuma ação durante $escalationDelay.",
                "تم تصعيد طلب الموافقة الخاص بـ <strong>$approvalName</strong> إليك، لأن الموافِق السابق لم يتخذ أي إجراء خلال $escalationDelay.",
            ),
            "previous": ("Previous approver", "Aprobador anterior", "Approbateur précédent", "Approvatore precedente", "Vorherige genehmigende Person", "Aprovador anterior", "الموافِق السابق"),
        },
        content=f"""
#if($previousApprover.identityID == $__recipient.id)
{p("$tx_fromYou")}
{details(SUBMITTED_ROWS)}
#else
{p("$tx_toYou")}
{details([*SUBMITTED_ROWS, ("$tx_previous", "$previousApprover.name", "$previousApprover.name && $previousApprover.name != ''")])}
{button(APPROVER_LINK, "$tx_reviewNow")}
#end
""",
        sample={"escalationDelay": "3 days", "requester.name": "Marco Rossi", "previousApprover.name": "Lena Müller", "previousApprover.identityID": "x2"},
    ),
    Rewrite(
        key="approval_request_escalation_requester",
        greet=R2,
        subject=(
            "#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)An approval request submitted on your behalf has been escalated#{else}Your approval request has been escalated#end",
            "#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)Se ha escalado una solicitud de aprobación enviada en tu nombre#{else}Se ha escalado tu solicitud de aprobación#end",
            "#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)Une demande d’approbation envoyée en votre nom a été remontée#{else}Votre demande d’approbation a été remontée#end",
            "#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)Una richiesta di approvazione inviata per tuo conto è stata inoltrata#{else}La tua richiesta di approvazione è stata inoltrata#end",
            "#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)Eine in Ihrem Namen gestellte Genehmigungsanfrage wurde eskaliert#{else}Ihre Genehmigungsanfrage wurde eskaliert#end",
            "#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)Um pedido de aprovação enviado em seu nome foi escalado#{else}O seu pedido de aprovação foi escalado#end",
            "#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)تم تصعيد طلب موافقة مقدَّم نيابةً عنك#{else}تم تصعيد طلب الموافقة الخاص بك#end",
        ),
        prelude="""
#set($emeaOnBehalf = false)#if($requestee.name && $requestee.name != '' && $requester.identityID != $__recipient.id)#set($emeaOnBehalf = true)#end
#set($emeaFromPrev = false)#if($previousApprover.name && $previousApprover.name != '')#set($emeaFromPrev = true)#end
""",
        strings={
            "introOnBehalf": (
                "The approval request for <strong>$approvalName</strong>, submitted on your behalf by $requester.name, had no action for $escalationDelay.",
                "La solicitud de aprobación de <strong>$approvalName</strong>, enviada en tu nombre por $requester.name, lleva $escalationDelay sin ninguna acción.",
                "La demande d’approbation de <strong>$approvalName</strong>, envoyée en votre nom par $requester.name, n’a fait l’objet d’aucune action pendant $escalationDelay.",
                "La richiesta di approvazione di <strong>$approvalName</strong>, inviata per tuo conto da $requester.name, non ha ricevuto alcuna azione per $escalationDelay.",
                "Für die Genehmigungsanfrage für <strong>$approvalName</strong>, die $requester.name in Ihrem Namen gestellt hat, ist $escalationDelay lang keine Aktion erfolgt.",
                "O pedido de aprovação de <strong>$approvalName</strong>, enviado em seu nome por $requester.name, não teve nenhuma ação durante $escalationDelay.",
                "لم يُتخذ أي إجراء بشأن طلب الموافقة الخاص بـ <strong>$approvalName</strong>، الذي قدّمه $requester.name نيابةً عنك، خلال $escalationDelay.",
            ),
            "introYou": (
                "Your approval request for <strong>$approvalName</strong> had no action for $escalationDelay.",
                "Tu solicitud de aprobación de <strong>$approvalName</strong> lleva $escalationDelay sin ninguna acción.",
                "Votre demande d’approbation de <strong>$approvalName</strong> n’a fait l’objet d’aucune action pendant $escalationDelay.",
                "La tua richiesta di approvazione di <strong>$approvalName</strong> non ha ricevuto alcuna azione per $escalationDelay.",
                "Für Ihre Genehmigungsanfrage für <strong>$approvalName</strong> ist $escalationDelay lang keine Aktion erfolgt.",
                "O seu pedido de aprovação de <strong>$approvalName</strong> não teve nenhuma ação durante $escalationDelay.",
                "لم يُتخذ أي إجراء بشأن طلب الموافقة الخاص بك لـ <strong>$approvalName</strong> خلال $escalationDelay.",
            ),
            "escalatedFrom": (
                "It has been escalated from $previousApprover.name to <strong>$escalatedApprover.name</strong>.",
                "Se ha escalado de $previousApprover.name a <strong>$escalatedApprover.name</strong>.",
                "Elle a été remontée de $previousApprover.name à <strong>$escalatedApprover.name</strong>.",
                "È stata inoltrata da $previousApprover.name a <strong>$escalatedApprover.name</strong>.",
                "Sie wurde von $previousApprover.name an <strong>$escalatedApprover.name</strong> eskaliert.",
                "Foi escalado de $previousApprover.name para <strong>$escalatedApprover.name</strong>.",
                "تم تصعيده من $previousApprover.name إلى <strong>$escalatedApprover.name</strong>.",
            ),
            "escalated": (
                "It has been escalated to <strong>$escalatedApprover.name</strong>.",
                "Se ha escalado a <strong>$escalatedApprover.name</strong>.",
                "Elle a été remontée à <strong>$escalatedApprover.name</strong>.",
                "È stata inoltrata a <strong>$escalatedApprover.name</strong>.",
                "Sie wurde an <strong>$escalatedApprover.name</strong> eskaliert.",
                "Foi escalado para <strong>$escalatedApprover.name</strong>.",
                "تم تصعيده إلى <strong>$escalatedApprover.name</strong>.",
            ),
        },
        content=f"""
#if($emeaOnBehalf)
{p("$tx_introOnBehalf")}
#else
{p("$tx_introYou")}
#end
#if($emeaFromPrev){info("$tx_escalatedFrom")}#else{info("$tx_escalated")}#end
{button(REQUESTER_LINK, "$tx_viewRequests")}
""",
        sample={"escalationDelay": "3 days", "escalatedApprover.name": "Lena Müller"},
    ),
    Rewrite(
        key="approval_request_notification",
        greet=R2,
        subject=(
            "#if($__contentJson.batchSize == 1)An approval request is waiting for your review#{else}$__contentJson.batchSize approval requests are waiting for your review#end",
            "#if($__contentJson.batchSize == 1)Tienes una solicitud de aprobación pendiente de revisión#{else}Tienes $__contentJson.batchSize solicitudes de aprobación pendientes de revisión#end",
            "#if($__contentJson.batchSize == 1)Une demande d’approbation attend votre examen#{else}$__contentJson.batchSize demandes d’approbation attendent votre examen#end",
            "#if($__contentJson.batchSize == 1)Una richiesta di approvazione è in attesa della tua revisione#{else}$__contentJson.batchSize richieste di approvazione sono in attesa della tua revisione#end",
            "#if($__contentJson.batchSize == 1)Eine Genehmigungsanfrage wartet auf Ihre Prüfung#{else}$__contentJson.batchSize Genehmigungsanfragen warten auf Ihre Prüfung#end",
            "#if($__contentJson.batchSize == 1)Um pedido de aprovação aguarda a sua revisão#{else}$__contentJson.batchSize pedidos de aprovação aguardam a sua revisão#end",
            "#if($__contentJson.batchSize == 1)طلب موافقة بانتظار مراجعتك#{else}$__contentJson.batchSize طلبات موافقة بانتظار مراجعتك#end",
        ),
        strings={
            "one": (
                "You have <strong>1 approval request</strong> waiting for your review.",
                "Tienes <strong>1 solicitud de aprobación</strong> pendiente de revisión.",
                "<strong>1 demande d’approbation</strong> attend votre examen.",
                "Hai <strong>1 richiesta di approvazione</strong> in attesa della tua revisione.",
                "<strong>1 Genehmigungsanfrage</strong> wartet auf Ihre Prüfung.",
                "Tem <strong>1 pedido de aprovação</strong> a aguardar a sua revisão.",
                "لديك <strong>طلب موافقة واحد</strong> بانتظار مراجعتك.",
            ),
            "many": (
                "You have <strong>$__contentJson.batchSize approval requests</strong> waiting for your review.",
                "Tienes <strong>$__contentJson.batchSize solicitudes de aprobación</strong> pendientes de revisión.",
                "<strong>$__contentJson.batchSize demandes d’approbation</strong> attendent votre examen.",
                "Hai <strong>$__contentJson.batchSize richieste di approvazione</strong> in attesa della tua revisione.",
                "<strong>$__contentJson.batchSize Genehmigungsanfragen</strong> warten auf Ihre Prüfung.",
                "Tem <strong>$__contentJson.batchSize pedidos de aprovação</strong> a aguardar a sua revisão.",
                "لديك <strong>$__contentJson.batchSize طلبات موافقة</strong> بانتظار مراجعتك.",
            ),
        },
        content=f"""
#if($__contentJson.batchSize == 1){p("$tx_one")}#else{p("$tx_many")}#end
{button(APPROVER_LINK, "$tx_reviewNow")}
""",
        sample={"__contentJson.batchSize": "int:3"},
    ),
    Rewrite(
        key="approval_request_reminder",
        greet=R2,
        subject=(
            "Reminder: an approval request is waiting for your review",
            "Recordatorio: tienes una solicitud de aprobación pendiente de revisión",
            "Rappel : une demande d’approbation attend votre examen",
            "Promemoria: una richiesta di approvazione è in attesa della tua revisione",
            "Erinnerung: Eine Genehmigungsanfrage wartet auf Ihre Prüfung",
            "Lembrete: um pedido de aprovação aguarda a sua revisão",
            "تذكير: طلب موافقة بانتظار مراجعتك",
        ),
        strings={
            "intro": (
                "This is a reminder that the approval request for <strong>$approvalName</strong> is still waiting for your review.",
                "Te recordamos que la solicitud de aprobación de <strong>$approvalName</strong> sigue pendiente de tu revisión.",
                "Pour rappel, la demande d’approbation de <strong>$approvalName</strong> attend toujours votre examen.",
                "Ti ricordiamo che la richiesta di approvazione di <strong>$approvalName</strong> è ancora in attesa della tua revisione.",
                "Zur Erinnerung: Die Genehmigungsanfrage für <strong>$approvalName</strong> wartet noch auf Ihre Prüfung.",
                "Lembramos que o pedido de aprovação de <strong>$approvalName</strong> continua a aguardar a sua revisão.",
                "نذكّرك بأن طلب الموافقة الخاص بـ <strong>$approvalName</strong> لا يزال بانتظار مراجعتك.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{details(SUBMITTED_ROWS)}
{button(APPROVER_LINK, "$tx_reviewNow")}
""",
        sample={"requester.name": "Marco Rossi"},
    ),
    Rewrite(
        key="approval_request_timeout",
        greet=R2,
        subject=(
            "An approval request has timed out",
            "Una solicitud de aprobación ha caducado",
            "Une demande d’approbation a expiré",
            "Una richiesta di approvazione è scaduta",
            "Eine Genehmigungsanfrage ist abgelaufen",
            "Um pedido de aprovação expirou",
            "انتهت مهلة طلب موافقة",
        ),
        prelude=WHO,
        strings={
            "introOnBehalf": (
                "The approval request for <strong>$approvalName</strong>, submitted on your behalf by $requester.name, was not resolved within $timeoutDays days and is now closed.",
                "La solicitud de aprobación de <strong>$approvalName</strong>, enviada en tu nombre por $requester.name, no se ha resuelto en $timeoutDays días y se ha cerrado.",
                "La demande d’approbation de <strong>$approvalName</strong>, envoyée en votre nom par $requester.name, n’a pas été traitée dans un délai de $timeoutDays jours et est désormais close.",
                "La richiesta di approvazione di <strong>$approvalName</strong>, inviata per tuo conto da $requester.name, non è stata risolta entro $timeoutDays giorni ed è stata chiusa.",
                "Die Genehmigungsanfrage für <strong>$approvalName</strong>, die $requester.name in Ihrem Namen gestellt hat, wurde nicht innerhalb von $timeoutDays Tagen bearbeitet und ist jetzt geschlossen.",
                "O pedido de aprovação de <strong>$approvalName</strong>, enviado em seu nome por $requester.name, não foi resolvido em $timeoutDays dias e foi encerrado.",
                "لم تتم معالجة طلب الموافقة الخاص بـ <strong>$approvalName</strong>، الذي قدّمه $requester.name نيابةً عنك، خلال $timeoutDays أيام، وقد تم إغلاقه.",
            ),
            "introYou": (
                "Your approval request for <strong>$approvalName</strong> was not resolved within $timeoutDays days and is now closed.",
                "Tu solicitud de aprobación de <strong>$approvalName</strong> no se ha resuelto en $timeoutDays días y se ha cerrado.",
                "Votre demande d’approbation de <strong>$approvalName</strong> n’a pas été traitée dans un délai de $timeoutDays jours et est désormais close.",
                "La tua richiesta di approvazione di <strong>$approvalName</strong> non è stata risolta entro $timeoutDays giorni ed è stata chiusa.",
                "Ihre Genehmigungsanfrage für <strong>$approvalName</strong> wurde nicht innerhalb von $timeoutDays Tagen bearbeitet und ist jetzt geschlossen.",
                "O seu pedido de aprovação de <strong>$approvalName</strong> não foi resolvido em $timeoutDays dias e foi encerrado.",
                "لم تتم معالجة طلب الموافقة الخاص بك لـ <strong>$approvalName</strong> خلال $timeoutDays أيام، وقد تم إغلاقه.",
            ),
            "introOther": (
                "The approval request for <strong>$approvalName</strong>, submitted by $emeaBy, was not resolved within $timeoutDays days and is now closed.",
                "La solicitud de aprobación de <strong>$approvalName</strong>, enviada por $emeaBy, no se ha resuelto en $timeoutDays días y se ha cerrado.",
                "La demande d’approbation de <strong>$approvalName</strong>, envoyée par $emeaBy, n’a pas été traitée dans un délai de $timeoutDays jours et est désormais close.",
                "La richiesta di approvazione di <strong>$approvalName</strong>, inviata da $emeaBy, non è stata risolta entro $timeoutDays giorni ed è stata chiusa.",
                "Die Genehmigungsanfrage für <strong>$approvalName</strong> von $emeaBy wurde nicht innerhalb von $timeoutDays Tagen bearbeitet und ist jetzt geschlossen.",
                "O pedido de aprovação de <strong>$approvalName</strong>, enviado por $emeaBy, não foi resolvido em $timeoutDays dias e foi encerrado.",
                "لم تتم معالجة طلب الموافقة الخاص بـ <strong>$approvalName</strong>، الذي قدّمه $emeaBy، خلال $timeoutDays أيام، وقد تم إغلاقه.",
            ),
            "newRequest": (
                "You can submit a new request if you still need it.",
                "Puedes enviar una nueva solicitud si todavía lo necesitas.",
                "Vous pouvez envoyer une nouvelle demande si vous en avez toujours besoin.",
                "Puoi inviare una nuova richiesta se ne hai ancora bisogno.",
                "Sie können eine neue Anfrage stellen, wenn Sie den Zugriff weiterhin benötigen.",
                "Pode enviar um novo pedido se ainda precisar.",
                "يمكنك تقديم طلب جديد إذا كنت لا تزال بحاجة إليه.",
            ),
        },
        content=who_content("intro")
        + f"""
#if($emeaMine)
{p("$tx_newRequest")}
#end"""
        + mine_button(),
        sample={"timeoutDays": "14", "requester.name": "Marco Rossi"},
    ),
    # ---------------------------------------------------------- certifications
    Rewrite(
        key="certification",
        greet="${user.name}",
        subject=(
            "Action required: review your team’s access",
            "Acción necesaria: revisa el acceso de tu equipo",
            "Action requise : examinez les accès de votre équipe",
            "Azione richiesta: verifica gli accessi del tuo team",
            "Handlungsbedarf: Prüfen Sie die Zugriffe Ihres Teams",
            "Ação necessária: reveja os acessos da sua equipa",
            "إجراء مطلوب: راجِع وصول فريقك",
        ),
        prelude=CERT_PRELUDE,
        strings={
            "intro": (
                "The <strong>$emeaCampaign</strong> certification campaign has started. Please confirm that each person you review has the right access.",
                "Ha comenzado la campaña de certificación <strong>$emeaCampaign</strong>. Confirma que cada persona que revisas tiene el acceso adecuado.",
                "La campagne de certification <strong>$emeaCampaign</strong> a commencé. Veuillez confirmer que chaque personne que vous examinez dispose des accès appropriés.",
                "È iniziata la campagna di certificazione <strong>$emeaCampaign</strong>. Conferma che ogni persona che esamini abbia gli accessi corretti.",
                "Die Zertifizierungskampagne <strong>$emeaCampaign</strong> hat begonnen. Bitte bestätigen Sie, dass jede von Ihnen geprüfte Person die richtigen Zugriffe hat.",
                "A campanha de certificação <strong>$emeaCampaign</strong> começou. Confirme que cada pessoa que revê tem os acessos adequados.",
                "بدأت حملة الاعتماد <strong>$emeaCampaign</strong>. يُرجى التأكد من أن كل شخص تراجعه لديه الوصول المناسب.",
            ),
            "how": (
                "For each person you will see their entitlements and, where available, the sources and applications they come from. You can approve, change or revoke each item.",
                "Para cada persona verás sus derechos y, cuando estén disponibles, los orígenes y aplicaciones de los que proceden. Puedes aprobar, cambiar o revocar cada elemento.",
                "Pour chaque personne, vous verrez ses droits d’accès et, le cas échéant, les sources et applications dont ils proviennent. Vous pouvez approuver, modifier ou révoquer chaque élément.",
                "Per ogni persona vedrai le autorizzazioni e, se disponibili, le origini e le applicazioni da cui provengono. Puoi approvare, modificare o revocare ogni elemento.",
                "Für jede Person sehen Sie die Berechtigungen und, sofern verfügbar, die Quellen und Anwendungen, aus denen sie stammen. Sie können jedes Element genehmigen, ändern oder entziehen.",
                "Para cada pessoa, verá os direitos de acesso e, quando disponíveis, as origens e aplicações de onde provêm. Pode aprovar, alterar ou revogar cada item.",
                "ستظهر لك لكل شخص استحقاقاته، والمصادر والتطبيقات التي تأتي منها حيثما توفّرت. يمكنك الموافقة على كل عنصر أو تغييره أو إلغاؤه.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{p("$tx_how")}
{details([("$tx_certificationLabel", "$emeaCampaign"), ("$tx_dueBy", "$emeaDue", "$emeaDue")])}
{button("$emeaCertUrl", "$tx_reviewCert")}
""",
    ),
    Rewrite(
        key="certification_due",
        greet="${ownerName}",
        subject=(
            "Reminder: your certification needs attention",
            "Recordatorio: tu certificación requiere atención",
            "Rappel : votre certification requiert votre attention",
            "Promemoria: la tua certificazione richiede attenzione",
            "Erinnerung: Ihre Zertifizierung erfordert Ihre Aufmerksamkeit",
            "Lembrete: a sua certificação requer atenção",
            "تذكير: الاعتماد الخاص بك يحتاج إلى متابعة",
        ),
        prelude=CERT_PRELUDE,
        strings={
            "intro": (
                "The certification <strong>$emeaCampaign</strong> is still open and needs to be completed.",
                "La certificación <strong>$emeaCampaign</strong> sigue abierta y debe completarse.",
                "La certification <strong>$emeaCampaign</strong> est toujours ouverte et doit être terminée.",
                "La certificazione <strong>$emeaCampaign</strong> è ancora aperta e deve essere completata.",
                "Die Zertifizierung <strong>$emeaCampaign</strong> ist noch offen und muss abgeschlossen werden.",
                "A certificação <strong>$emeaCampaign</strong> continua aberta e tem de ser concluída.",
                "لا يزال الاعتماد <strong>$emeaCampaign</strong> مفتوحًا ويجب إكماله.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{details([("$tx_certificationLabel", "$emeaCampaign"), ("$tx_dueBy", "$emeaDue", "$emeaDue")])}
{button("$emeaCertUrl", "$tx_reviewCert")}
""",
        sample={"ownerName": "Lena Müller"},
    ),
    Rewrite(
        key="bulk_reassignment",
        greet="${user.name}",
        subject=(
            "Certification reviews have been reassigned to you",
            "Se te han reasignado revisiones de certificación",
            "Des revues de certification vous ont été réattribuées",
            "Ti sono state riassegnate delle revisioni di certificazione",
            "Ihnen wurden Zertifizierungsprüfungen zugewiesen",
            "Foram-lhe reatribuídas revisões de certificação",
            "أُعيد إليك إسناد مراجعات الاعتماد",
        ),
        prelude=CERT_PRELUDE,
        strings={
            "one": (
                "${requesterName} has assigned <strong>1 person</strong> to you for review in a certification.",
                "${requesterName} te ha asignado <strong>1 persona</strong> para revisar en una certificación.",
                "${requesterName} vous a attribué <strong>1 personne</strong> à examiner dans une certification.",
                "${requesterName} ti ha assegnato <strong>1 persona</strong> da esaminare in una certificazione.",
                "${requesterName} hat Ihnen <strong>1 Person</strong> zur Prüfung in einer Zertifizierung zugewiesen.",
                "${requesterName} atribuiu-lhe <strong>1 pessoa</strong> para rever numa certificação.",
                "أسند إليك ${requesterName} <strong>شخصًا واحدًا</strong> لمراجعته في أحد الاعتمادات.",
            ),
            "many": (
                "${requesterName} has assigned <strong>${numNewIdentities} people</strong> to you for review in a certification.",
                "${requesterName} te ha asignado <strong>${numNewIdentities} personas</strong> para revisar en una certificación.",
                "${requesterName} vous a attribué <strong>${numNewIdentities} personnes</strong> à examiner dans une certification.",
                "${requesterName} ti ha assegnato <strong>${numNewIdentities} persone</strong> da esaminare in una certificazione.",
                "${requesterName} hat Ihnen <strong>${numNewIdentities} Personen</strong> zur Prüfung in einer Zertifizierung zugewiesen.",
                "${requesterName} atribuiu-lhe <strong>${numNewIdentities} pessoas</strong> para rever numa certificação.",
                "أسند إليك ${requesterName} <strong>${numNewIdentities} أشخاص</strong> لمراجعتهم في أحد الاعتمادات.",
            ),
            "reason": ("Reason for reassignment:", "Motivo de la reasignación:", "Motif de la réattribution :", "Motivo della riassegnazione:", "Grund für die Neuzuweisung:", "Motivo da reatribuição:", "سبب إعادة الإسناد:"),
            "task": (
                "Approve, change or revoke the access of each person before the due date.",
                "Aprueba, cambia o revoca el acceso de cada persona antes de la fecha límite.",
                "Approuvez, modifiez ou révoquez les accès de chaque personne avant la date limite.",
                "Approva, modifica o revoca gli accessi di ogni persona entro la scadenza.",
                "Genehmigen, ändern oder entziehen Sie die Zugriffe jeder Person vor dem Fälligkeitsdatum.",
                "Aprove, altere ou revogue os acessos de cada pessoa antes do prazo.",
                "وافق على وصول كل شخص أو غيّره أو ألغِه قبل الموعد النهائي.",
            ),
        },
        content=f"""
#if($numNewIdentities == 1){p("$tx_one")}#else{p("$tx_many")}#end
#if($description)
{p("$tx_reason")}
{quote("${description}")}
#end
{p("$tx_task")}
{details([("$tx_certificationLabel", "$emeaCampaign"), ("$tx_dueBy", "$emeaDue", "$emeaDue")])}
{button("$emeaCertUrl", "$tx_reviewCert")}
""",
        sample={"numNewIdentities": "int:4", "description": "Team restructuring."},
    ),
    Rewrite(
        key="certification_end_date_modified_notification",
        greet=R2,
        subject=(
            "The end date of your access to $accessItemName has changed",
            "Ha cambiado la fecha de finalización de tu acceso a $accessItemName",
            "La date de fin de votre accès à $accessItemName a changé",
            "La data di fine del tuo accesso a $accessItemName è cambiata",
            "Das Enddatum Ihres Zugriffs auf $accessItemName wurde geändert",
            "A data de fim do seu acesso a $accessItemName foi alterada",
            "تغيّر تاريخ انتهاء وصولك إلى $accessItemName",
        ),
        strings={
            "intro": (
                "Your access to <strong>$accessItemName</strong> ($accessItemType) is now scheduled to end on <strong>$scheduledSunsetDate</strong>.",
                "Tu acceso a <strong>$accessItemName</strong> ($accessItemType) finalizará ahora el <strong>$scheduledSunsetDate</strong>.",
                "Votre accès à <strong>$accessItemName</strong> ($accessItemType) prendra désormais fin le <strong>$scheduledSunsetDate</strong>.",
                "Il tuo accesso a <strong>$accessItemName</strong> ($accessItemType) terminerà ora il <strong>$scheduledSunsetDate</strong>.",
                "Ihr Zugriff auf <strong>$accessItemName</strong> ($accessItemType) endet jetzt am <strong>$scheduledSunsetDate</strong>.",
                "O seu acesso a <strong>$accessItemName</strong> ($accessItemType) termina agora em <strong>$scheduledSunsetDate</strong>.",
                "أصبح من المقرر أن ينتهي وصولك إلى <strong>$accessItemName</strong> ($accessItemType) في <strong>$scheduledSunsetDate</strong>.",
            ),
            "extend": (
                "If you still need it after this date, request it again to extend it.",
                "Si lo necesitas después de esa fecha, vuelve a solicitarlo para ampliarlo.",
                "Si vous en avez encore besoin après cette date, demandez-le à nouveau pour le prolonger.",
                "Se ne hai bisogno dopo tale data, richiedilo di nuovo per estenderlo.",
                "Wenn Sie den Zugriff nach diesem Datum noch benötigen, beantragen Sie ihn erneut, um ihn zu verlängern.",
                "Se ainda precisar depois desta data, peça-o novamente para o prolongar.",
                "إذا كنت لا تزال بحاجة إليه بعد هذا التاريخ، فاطلبه مرة أخرى لتمديده.",
            ),
        },
        content=f"""
{info("$tx_intro")}
{p("$tx_extend")}
{p("$tx_contactAdmin")}
""",
        sample={"accessItemName": "Finance Reporting", "accessItemType": "role", "scheduledSunsetDate": "Dec 31, 2026"},
    ),
    Rewrite(
        key="remediation_work_item",
        subject=(
            "New remediation request: $!workItemName",
            "Nueva solicitud de corrección: $!workItemName",
            "Nouvelle demande de remédiation : $!workItemName",
            "Nuova richiesta di correzione: $!workItemName",
            "Neue Korrekturanfrage: $!workItemName",
            "Novo pedido de correção: $!workItemName",
            "طلب معالجة جديد: $!workItemName",
        ),
        strings={
            "intro": (
                "$!requesterName has assigned you a new remediation work item: <strong>$!workItemName</strong>.",
                "$!requesterName te ha asignado una nueva tarea de corrección: <strong>$!workItemName</strong>.",
                "$!requesterName vous a attribué une nouvelle tâche de remédiation : <strong>$!workItemName</strong>.",
                "$!requesterName ti ha assegnato una nuova attività di correzione: <strong>$!workItemName</strong>.",
                "$!requesterName hat Ihnen eine neue Korrekturaufgabe zugewiesen: <strong>$!workItemName</strong>.",
                "$!requesterName atribuiu-lhe uma nova tarefa de correção: <strong>$!workItemName</strong>.",
                "أسند إليك $!requesterName عنصر عمل جديدًا للمعالجة: <strong>$!workItemName</strong>.",
            ),
            "comments": ("Comments from $!requesterName:", "Comentarios de $!requesterName:", "Commentaires de $!requesterName :", "Commenti di $!requesterName:", "Kommentare von $!requesterName:", "Comentários de $!requesterName:", "تعليقات $!requesterName:"),
            "next": (
                "Sign in and open your work item inbox to complete it.",
                "Inicia sesión y abre tu bandeja de tareas para completarla.",
                "Connectez-vous et ouvrez votre boîte de réception des tâches pour la traiter.",
                "Accedi e apri la tua casella delle attività per completarla.",
                "Melden Sie sich an und öffnen Sie Ihren Aufgabeneingang, um sie zu erledigen.",
                "Inicie sessão e abra a sua caixa de tarefas para a concluir.",
                "سجّل الدخول وافتح صندوق عناصر العمل لإكماله.",
            ),
        },
        content=f"""
{p("$tx_intro")}
#if($comments && $comments != '')
{p("$tx_comments")}
{quote("$!comments")}
#end
{p("$tx_next")}
""",
        sample={"workItemName": "Revoke FIN-Ledger-Admin from Ana García", "comments": "Flagged in the Q3 review."},
    ),
    # -------------------------------------------------------------- work items
    Rewrite(
        key="cloud_manual_work_item_summary",
        greet=R2,
        subject=tuple(
            "#set($numberOfPendingTasks = $__numberTool.integer($numberOfPendingTasks))" + s
            for s in (
                "#if($numberOfPendingTasks == 1)You have 1 task to complete in " + PN2 + "#{else}You have $numberOfPendingTasks tasks to complete in " + PN2 + "#end",
                "#if($numberOfPendingTasks == 1)Tienes 1 tarea pendiente en " + PN2 + "#{else}Tienes $numberOfPendingTasks tareas pendientes en " + PN2 + "#end",
                "#if($numberOfPendingTasks == 1)Vous avez 1 tâche à effectuer dans " + PN2 + "#{else}Vous avez $numberOfPendingTasks tâches à effectuer dans " + PN2 + "#end",
                "#if($numberOfPendingTasks == 1)Hai 1 attività da completare in " + PN2 + "#{else}Hai $numberOfPendingTasks attività da completare in " + PN2 + "#end",
                "#if($numberOfPendingTasks == 1)Sie haben 1 offene Aufgabe in " + PN2 + "#{else}Sie haben $numberOfPendingTasks offene Aufgaben in " + PN2 + "#end",
                "#if($numberOfPendingTasks == 1)Tem 1 tarefa por concluir no " + PN2 + "#{else}Tem $numberOfPendingTasks tarefas por concluir no " + PN2 + "#end",
                "#if($numberOfPendingTasks == 1)لديك مهمة واحدة لإكمالها في " + PN2 + "#{else}لديك $numberOfPendingTasks مهام لإكمالها في " + PN2 + "#end",
            )
        ),
        prelude="""
#set($numberOfPendingTasks = $__numberTool.integer($numberOfPendingTasks))
#set($emeaUrl = "${__global.productUrl}/ui/d/dashboard/task-manager")
""",
        strings={
            "one": (
                "You have <strong>1 task</strong> waiting in your Task Manager.",
                "Tienes <strong>1 tarea</strong> pendiente en tu Administrador de tareas.",
                "Vous avez <strong>1 tâche</strong> en attente dans votre gestionnaire de tâches.",
                "Hai <strong>1 attività</strong> in attesa nel tuo Task Manager.",
                "In Ihrem Aufgabenmanager wartet <strong>1 Aufgabe</strong>.",
                "Tem <strong>1 tarefa</strong> pendente no seu Gestor de tarefas.",
                "لديك <strong>مهمة واحدة</strong> بانتظارك في Task Manager.",
            ),
            "many": (
                "You have <strong>$numberOfPendingTasks tasks</strong> waiting in your Task Manager.",
                "Tienes <strong>$numberOfPendingTasks tareas</strong> pendientes en tu Administrador de tareas.",
                "Vous avez <strong>$numberOfPendingTasks tâches</strong> en attente dans votre gestionnaire de tâches.",
                "Hai <strong>$numberOfPendingTasks attività</strong> in attesa nel tuo Task Manager.",
                "In Ihrem Aufgabenmanager warten <strong>$numberOfPendingTasks Aufgaben</strong>.",
                "Tem <strong>$numberOfPendingTasks tarefas</strong> pendentes no seu Gestor de tarefas.",
                "لديك <strong>$numberOfPendingTasks مهام</strong> بانتظارك في Task Manager.",
            ),
            "how": (
                "For each task, use its details to make the change on the source, then mark it as complete in " + PN2 + ".",
                "Para cada tarea, usa sus detalles para hacer el cambio en el origen y, después, márcala como completada en " + PN2 + ".",
                "Pour chaque tâche, utilisez ses détails pour effectuer la modification sur la source, puis marquez-la comme terminée dans " + PN2 + ".",
                "Per ogni attività, usa i relativi dettagli per apportare la modifica sull’origine, quindi contrassegnala come completata in " + PN2 + ".",
                "Nehmen Sie für jede Aufgabe anhand der Details die Änderung in der Quelle vor und markieren Sie sie anschließend in " + PN2 + " als erledigt.",
                "Para cada tarefa, utilize os detalhes para efetuar a alteração na origem e, depois, marque-a como concluída no " + PN2 + ".",
                "لكل مهمة، استخدم تفاصيلها لإجراء التغيير على المصدر، ثم ضع عليها علامة مكتملة في " + PN2 + ".",
            ),
            "open": ("Open Task Manager", "Abrir Administrador de tareas", "Ouvrir le gestionnaire de tâches", "Apri Task Manager", "Aufgabenmanager öffnen", "Abrir Gestor de tarefas", "فتح Task Manager"),
        },
        content=f"""
#if($numberOfPendingTasks == 1){p("$tx_one")}#else{p("$tx_many")}#end
{p("$tx_how")}
{button("$emeaUrl", "$tx_open")}
""",
        sample={"numberOfPendingTasks": "3"},
    ),
    Rewrite(
        key="task_reassignment",
        subject=(
            "A task has been reassigned",
            "Se ha reasignado una tarea",
            "Une tâche a été réattribuée",
            "Un’attività è stata riassegnata",
            "Eine Aufgabe wurde neu zugewiesen",
            "Uma tarefa foi reatribuída",
            "تمت إعادة إسناد مهمة",
        ),
        strings={
            "intro": (
                "${requester} has reassigned a task for ${userName}’s ${source} account from ${previousOwner} to <strong>${newOwner}</strong>.",
                "${requester} ha reasignado una tarea de la cuenta de ${source} de ${userName} de ${previousOwner} a <strong>${newOwner}</strong>.",
                "${requester} a réattribué une tâche concernant le compte ${source} de ${userName} de ${previousOwner} à <strong>${newOwner}</strong>.",
                "${requester} ha riassegnato un’attività relativa all’account ${source} di ${userName} da ${previousOwner} a <strong>${newOwner}</strong>.",
                "${requester} hat eine Aufgabe für das ${source}-Konto von ${userName} von ${previousOwner} an <strong>${newOwner}</strong> neu zugewiesen.",
                "${requester} reatribuiu uma tarefa da conta ${source} de ${userName} de ${previousOwner} para <strong>${newOwner}</strong>.",
                "أعاد ${requester} إسناد مهمة تخص حساب ${userName} على ${source} من ${previousOwner} إلى <strong>${newOwner}</strong>.",
            ),
            "where": (
                "${newOwner} can find it in the Task Manager.",
                "${newOwner} puede encontrarla en el Administrador de tareas.",
                "${newOwner} la trouvera dans le gestionnaire de tâches.",
                "${newOwner} può trovarla nel Task Manager.",
                "${newOwner} findet sie im Aufgabenmanager.",
                "${newOwner} pode encontrá-la no Gestor de tarefas.",
                "يمكن لـ ${newOwner} العثور عليها في Task Manager.",
            ),
            "open": ("Open Task Manager", "Abrir Administrador de tareas", "Ouvrir le gestionnaire de tâches", "Apri Task Manager", "Aufgabenmanager öffnen", "Abrir Gestor de tarefas", "فتح Task Manager"),
        },
        content=f"""
{p("$tx_intro")}
{p("$tx_where")}
{button("$identityNowUrl/ui/d/dashboard/task-manager", "$tx_open")}
""",
        sample={"requester": "Marco Rossi", "userName": "Ana García", "source": "SAP", "previousOwner": "Lena Müller", "newOwner": "João Silva"},
    ),
    Rewrite(
        key="work_item_forward",
        subject=(
            "Work item forwarded: $workItemName",
            "Tarea reenviada: $workItemName",
            "Tâche transférée : $workItemName",
            "Attività inoltrata: $workItemName",
            "Aufgabe weitergeleitet: $workItemName",
            "Tarefa reencaminhada: $workItemName",
            "تمت إعادة توجيه عنصر العمل: $workItemName",
        ),
        prelude="""
#set($emeaForwardDate = "$spTools.formatDate($forwardDate,3,1)")
""",
        strings={
            "intro": (
                "$requester forwarded the work item <strong>$workItemName</strong> from $previousOwner to <strong>$newOwner</strong> on $emeaForwardDate.",
                "$requester reenvió la tarea <strong>$workItemName</strong> de $previousOwner a <strong>$newOwner</strong> el $emeaForwardDate.",
                "$requester a transféré la tâche <strong>$workItemName</strong> de $previousOwner à <strong>$newOwner</strong> le $emeaForwardDate.",
                "$requester ha inoltrato l’attività <strong>$workItemName</strong> da $previousOwner a <strong>$newOwner</strong> il $emeaForwardDate.",
                "$requester hat die Aufgabe <strong>$workItemName</strong> am $emeaForwardDate von $previousOwner an <strong>$newOwner</strong> weitergeleitet.",
                "$requester reencaminhou a tarefa <strong>$workItemName</strong> de $previousOwner para <strong>$newOwner</strong> em $emeaForwardDate.",
                "أعاد $requester توجيه عنصر العمل <strong>$workItemName</strong> من $previousOwner إلى <strong>$newOwner</strong> في $emeaForwardDate.",
            ),
        },
        content=f"""
{p("$tx_intro")}
#if($commentText && $commentText != '')
{p("<strong>$tx_comment:</strong>")}
{quote("$!commentText")}
#end
""",
        sample={"requester": "Marco Rossi", "workItemName": "Approve VPN access", "previousOwner": "Lena Müller", "newOwner": "João Silva", "forwardDate": "Oct 14, 2026", "commentText": "Covering while Lena is away."},
    ),
    Rewrite(
        key="work_reassignment_created",
        greet=R2,
        subject=(
            "New automatic reassignment for ${reassignedFromName}",
            "Nueva reasignación automática para ${reassignedFromName}",
            "Nouvelle réattribution automatique pour ${reassignedFromName}",
            "Nuova riassegnazione automatica per ${reassignedFromName}",
            "Neue automatische Neuzuweisung für ${reassignedFromName}",
            "Nova reatribuição automática para ${reassignedFromName}",
            "إعادة إسناد تلقائي جديدة لـ ${reassignedFromName}",
        ),
        prelude=reassignment_prelude(""),
        strings=reassignment_strings(""),
        content=REASSIGNMENT_CONTENT,
        sample={"modifiedByName": "Lena Müller", "configType": "access requests", "reassignedFromName": "Lena Müller", "reassignedToName": "João Silva", "startDate": "2026-10-20T00:00:00Z", "endDate": "0001-01-01T00:00:00Z"},
    ),
    Rewrite(
        key="work_reassignment_updated",
        greet=R2,
        subject=(
            "Automatic reassignment updated for ${newConfig.reassignedFromName}",
            "Reasignación automática actualizada para ${newConfig.reassignedFromName}",
            "Réattribution automatique mise à jour pour ${newConfig.reassignedFromName}",
            "Riassegnazione automatica aggiornata per ${newConfig.reassignedFromName}",
            "Automatische Neuzuweisung für ${newConfig.reassignedFromName} aktualisiert",
            "Reatribuição automática atualizada para ${newConfig.reassignedFromName}",
            "تم تحديث إعادة الإسناد التلقائي لـ ${newConfig.reassignedFromName}",
        ),
        prelude=reassignment_prelude("newConfig."),
        strings=reassignment_strings("newConfig."),
        content=REASSIGNMENT_CONTENT,
        sample={"newConfig.modifiedByName": "Lena Müller", "newConfig.configType": "access requests", "newConfig.reassignedFromName": "Lena Müller", "newConfig.reassignedToName": "João Silva", "newConfig.startDate": "2026-10-20T00:00:00Z", "newConfig.endDate": "2026-11-20T00:00:00Z"},
    ),
    # ------------------------------------------------------- Just-In-Time access
    Rewrite(
        key="jit_access_request_assignment",
        greet=R2,
        subject=(
            "Your access request for ${requestedObjectName} has been assigned",
            "Se ha asignado tu solicitud de acceso a ${requestedObjectName}",
            "Votre demande d’accès à ${requestedObjectName} a été attribuée",
            "La tua richiesta di accesso a ${requestedObjectName} è stata assegnata",
            "Ihre Zugriffsanfrage für ${requestedObjectName} wurde zugewiesen",
            "O seu pedido de acesso a ${requestedObjectName} foi atribuído",
            "تم إسناد طلب الوصول الخاص بك لـ ${requestedObjectName}",
        ),
        strings={
            "intro": (
                "Your request for the <strong>${requestedObjectName}</strong> entitlement has been assigned.",
                "Se ha asignado tu solicitud del derecho <strong>${requestedObjectName}</strong>.",
                "Votre demande du droit d’accès <strong>${requestedObjectName}</strong> a été attribuée.",
                "La tua richiesta dell’autorizzazione <strong>${requestedObjectName}</strong> è stata assegnata.",
                "Ihre Anfrage für die Berechtigung <strong>${requestedObjectName}</strong> wurde zugewiesen.",
                "O seu pedido do direito de acesso <strong>${requestedObjectName}</strong> foi atribuído.",
                "تم إسناد طلبك للحصول على الاستحقاق <strong>${requestedObjectName}</strong>.",
            ),
            "jit": JIT_NOTE,
        },
        content=f"""
{p("$tx_intro")}
{info("$tx_jit")}
#if($removeDate)
{details([("$tx_endsOn", "${removeDate}")])}
#end
""",
    ),
    Rewrite(
        key="jit_activation_extended",
        greet=R2,
        subject=(
            "Your Just-In-Time access to ${entitlementName} has been extended",
            "Se ha ampliado tu acceso Just-In-Time a ${entitlementName}",
            "Votre accès Just-In-Time à ${entitlementName} a été prolongé",
            "Il tuo accesso Just-In-Time a ${entitlementName} è stato esteso",
            "Ihr Just-In-Time-Zugriff auf ${entitlementName} wurde verlängert",
            "O seu acesso Just-In-Time a ${entitlementName} foi prolongado",
            "تم تمديد وصول Just-In-Time الخاص بك إلى ${entitlementName}",
        ),
        strings={
            "intro": (
                "Your Just-In-Time access to <strong>${entitlementName}</strong> has been extended by <strong>${extensionDuration}</strong>.",
                "Tu acceso Just-In-Time a <strong>${entitlementName}</strong> se ha ampliado <strong>${extensionDuration}</strong> más.",
                "Votre accès Just-In-Time à <strong>${entitlementName}</strong> a été prolongé de <strong>${extensionDuration}</strong>.",
                "Il tuo accesso Just-In-Time a <strong>${entitlementName}</strong> è stato esteso di <strong>${extensionDuration}</strong>.",
                "Ihr Just-In-Time-Zugriff auf <strong>${entitlementName}</strong> wurde um <strong>${extensionDuration}</strong> verlängert.",
                "O seu acesso Just-In-Time a <strong>${entitlementName}</strong> foi prolongado por mais <strong>${extensionDuration}</strong>.",
                "تم تمديد وصول Just-In-Time الخاص بك إلى <strong>${entitlementName}</strong> بمقدار <strong>${extensionDuration}</strong>.",
            ),
            "manageHint": (
                "You can extend it again or deactivate it early at any time.",
                "Puedes volver a ampliarlo o desactivarlo antes en cualquier momento.",
                "Vous pouvez le prolonger à nouveau ou le désactiver plus tôt à tout moment.",
                "Puoi estenderlo di nuovo o disattivarlo in anticipo in qualsiasi momento.",
                "Sie können ihn jederzeit erneut verlängern oder vorzeitig deaktivieren.",
                "Pode prolongá-lo novamente ou desativá-lo mais cedo em qualquer altura.",
                "يمكنك تمديده مرة أخرى أو إلغاء تفعيله مبكرًا في أي وقت.",
            ),
            "manage": MANAGE_ACCESS,
            "contactOwner": CONTACT_OWNER,
        },
        content=f"""
{info("$tx_intro")}
#if($activationUrl)
{p("$tx_manageHint")}
{button("$activationUrl", "$tx_manage")}
#end
{p("$tx_contactOwner")}
""",
        sample={"extensionDuration": "1 hour"},
    ),
    Rewrite(
        key="jit_activation_failed",
        greet=R2,
        subject=(
            "Your Just-In-Time access to ${entitlementName} could not be activated",
            "No se ha podido activar tu acceso Just-In-Time a ${entitlementName}",
            "Votre accès Just-In-Time à ${entitlementName} n’a pas pu être activé",
            "Non è stato possibile attivare il tuo accesso Just-In-Time a ${entitlementName}",
            "Ihr Just-In-Time-Zugriff auf ${entitlementName} konnte nicht aktiviert werden",
            "Não foi possível ativar o seu acesso Just-In-Time a ${entitlementName}",
            "تعذّر تفعيل وصول Just-In-Time الخاص بك إلى ${entitlementName}",
        ),
        strings={
            "intro": (
                "We could not activate your Just-In-Time access to <strong>${entitlementName}</strong>.",
                "No hemos podido activar tu acceso Just-In-Time a <strong>${entitlementName}</strong>.",
                "Nous n’avons pas pu activer votre accès Just-In-Time à <strong>${entitlementName}</strong>.",
                "Non è stato possibile attivare il tuo accesso Just-In-Time a <strong>${entitlementName}</strong>.",
                "Ihr Just-In-Time-Zugriff auf <strong>${entitlementName}</strong> konnte nicht aktiviert werden.",
                "Não foi possível ativar o seu acesso Just-In-Time a <strong>${entitlementName}</strong>.",
                "تعذّر علينا تفعيل وصول Just-In-Time الخاص بك إلى <strong>${entitlementName}</strong>.",
            ),
            "retry": ("Try again", "Volver a intentarlo", "Réessayer", "Riprova", "Erneut versuchen", "Tentar novamente", "حاول مرة أخرى"),
            "contactOwner": CONTACT_OWNER,
        },
        content=f"""
{note("$tx_intro")}
#if($activationUrl)
{button("$activationUrl", "$tx_retry")}
#end
{p("$tx_contactOwner")}
""",
    ),
    Rewrite(
        key="jit_activation_fifteen_min",
        greet=R2,
        subject=(
            "Your Just-In-Time access to ${entitlementName} expires in 15 minutes",
            "Tu acceso Just-In-Time a ${entitlementName} caduca en 15 minutos",
            "Votre accès Just-In-Time à ${entitlementName} expire dans 15 minutes",
            "Il tuo accesso Just-In-Time a ${entitlementName} scade tra 15 minuti",
            "Ihr Just-In-Time-Zugriff auf ${entitlementName} läuft in 15 Minuten ab",
            "O seu acesso Just-In-Time a ${entitlementName} expira dentro de 15 minutos",
            "ينتهي وصول Just-In-Time الخاص بك إلى ${entitlementName} خلال 15 دقيقة",
        ),
        strings={
            "intro": (
                "Your Just-In-Time access to <strong>${entitlementName}</strong> expires in <strong>15 minutes</strong>.",
                "Tu acceso Just-In-Time a <strong>${entitlementName}</strong> caduca en <strong>15 minutos</strong>.",
                "Votre accès Just-In-Time à <strong>${entitlementName}</strong> expire dans <strong>15 minutes</strong>.",
                "Il tuo accesso Just-In-Time a <strong>${entitlementName}</strong> scade tra <strong>15 minuti</strong>.",
                "Ihr Just-In-Time-Zugriff auf <strong>${entitlementName}</strong> läuft in <strong>15 Minuten</strong> ab.",
                "O seu acesso Just-In-Time a <strong>${entitlementName}</strong> expira dentro de <strong>15 minutos</strong>.",
                "ينتهي وصول Just-In-Time الخاص بك إلى <strong>${entitlementName}</strong> خلال <strong>15 دقيقة</strong>.",
            ),
            "application": APPLICATION,
            "manage": ("Extend or manage access", "Ampliar o gestionar acceso", "Prolonger ou gérer l’accès", "Estendi o gestisci accesso", "Zugriff verlängern oder verwalten", "Prolongar ou gerir acesso", "تمديد الوصول أو إدارته"),
        },
        content=f"""
{note("$tx_intro")}
#if($applicationName)
{details([("$tx_application", "$applicationName")])}
#end
#if($activationUrl)
{button("$activationUrl", "$tx_manage")}
#end
""",
        sample={"applicationName": "AWS Console"},
    ),
    Rewrite(
        key="jit_activation_fifteen_min_for_requested-for_identity",
        greet=R2,
        subject=(
            "Just-In-Time access for ${requestedForIdentityName} expires in 15 minutes",
            "El acceso Just-In-Time de ${requestedForIdentityName} caduca en 15 minutos",
            "L’accès Just-In-Time de ${requestedForIdentityName} expire dans 15 minutes",
            "L’accesso Just-In-Time di ${requestedForIdentityName} scade tra 15 minuti",
            "Just-In-Time-Zugriff von ${requestedForIdentityName} läuft in 15 Minuten ab",
            "O acesso Just-In-Time de ${requestedForIdentityName} expira dentro de 15 minutos",
            "ينتهي وصول Just-In-Time لـ ${requestedForIdentityName} خلال 15 دقيقة",
        ),
        strings={
            "intro": (
                "The Just-In-Time access that ${requestedForIdentityName} activated for <strong>${entitlementName}</strong> expires in <strong>15 minutes</strong>.",
                "El acceso Just-In-Time que ${requestedForIdentityName} activó para <strong>${entitlementName}</strong> caduca en <strong>15 minutos</strong>.",
                "L’accès Just-In-Time activé par ${requestedForIdentityName} pour <strong>${entitlementName}</strong> expire dans <strong>15 minutes</strong>.",
                "L’accesso Just-In-Time attivato da ${requestedForIdentityName} per <strong>${entitlementName}</strong> scade tra <strong>15 minuti</strong>.",
                "Der von ${requestedForIdentityName} aktivierte Just-In-Time-Zugriff auf <strong>${entitlementName}</strong> läuft in <strong>15 Minuten</strong> ab.",
                "O acesso Just-In-Time que ${requestedForIdentityName} ativou para <strong>${entitlementName}</strong> expira dentro de <strong>15 minutos</strong>.",
                "ينتهي وصول Just-In-Time الذي فعّله ${requestedForIdentityName} لـ <strong>${entitlementName}</strong> خلال <strong>15 دقيقة</strong>.",
            ),
            "application": APPLICATION,
        },
        content=f"""
{note("$tx_intro")}
#if($applicationName)
{details([("$tx_application", "$applicationName")])}
#end
""",
        sample={"applicationName": "AWS Console"},
    ),
    Rewrite(
        key="jit_activation_ready",
        greet=R2,
        subject=(
            "Your Just-In-Time access to ${entitlementName} is ready",
            "Tu acceso Just-In-Time a ${entitlementName} está listo",
            "Votre accès Just-In-Time à ${entitlementName} est prêt",
            "Il tuo accesso Just-In-Time a ${entitlementName} è pronto",
            "Ihr Just-In-Time-Zugriff auf ${entitlementName} ist bereit",
            "O seu acesso Just-In-Time a ${entitlementName} está pronto",
            "وصول Just-In-Time الخاص بك إلى ${entitlementName} جاهز",
        ),
        strings={
            "intro": (
                "Your Just-In-Time access to <strong>${entitlementName}</strong> is now active for <strong>${activationDuration}</strong>.",
                "Tu acceso Just-In-Time a <strong>${entitlementName}</strong> está activo durante <strong>${activationDuration}</strong>.",
                "Votre accès Just-In-Time à <strong>${entitlementName}</strong> est actif pour <strong>${activationDuration}</strong>.",
                "Il tuo accesso Just-In-Time a <strong>${entitlementName}</strong> è attivo per <strong>${activationDuration}</strong>.",
                "Ihr Just-In-Time-Zugriff auf <strong>${entitlementName}</strong> ist jetzt für <strong>${activationDuration}</strong> aktiv.",
                "O seu acesso Just-In-Time a <strong>${entitlementName}</strong> está ativo durante <strong>${activationDuration}</strong>.",
                "أصبح وصول Just-In-Time الخاص بك إلى <strong>${entitlementName}</strong> نشطًا لمدة <strong>${activationDuration}</strong>.",
            ),
            "manageHint": (
                "You can extend it or deactivate it early at any time.",
                "Puedes ampliarlo o desactivarlo antes en cualquier momento.",
                "Vous pouvez le prolonger ou le désactiver plus tôt à tout moment.",
                "Puoi estenderlo o disattivarlo in anticipo in qualsiasi momento.",
                "Sie können ihn jederzeit verlängern oder vorzeitig deaktivieren.",
                "Pode prolongá-lo ou desativá-lo mais cedo em qualquer altura.",
                "يمكنك تمديده أو إلغاء تفعيله مبكرًا في أي وقت.",
            ),
            "manage": MANAGE_ACCESS,
            "contactOwner": CONTACT_OWNER,
        },
        content=f"""
{info("$tx_intro")}
#if($activationUrl)
{p("$tx_manageHint")}
{button("$activationUrl", "$tx_manage")}
#end
{p("$tx_contactOwner")}
""",
        sample={"activationDuration": "2 hours"},
    ),
    Rewrite(
        key="jit_activation_ready_for_requested-for_identity",
        greet=R2,
        subject=(
            "Just-In-Time access for ${requestedForIdentityName} is ready",
            "El acceso Just-In-Time de ${requestedForIdentityName} está listo",
            "L’accès Just-In-Time de ${requestedForIdentityName} est prêt",
            "L’accesso Just-In-Time di ${requestedForIdentityName} è pronto",
            "Just-In-Time-Zugriff von ${requestedForIdentityName} ist bereit",
            "O acesso Just-In-Time de ${requestedForIdentityName} está pronto",
            "وصول Just-In-Time لـ ${requestedForIdentityName} جاهز",
        ),
        strings={
            "intro": (
                "The Just-In-Time access that ${requestedForIdentityName} started for <strong>${entitlementName}</strong> is now active for <strong>${activationDuration}</strong>.",
                "El acceso Just-In-Time que ${requestedForIdentityName} inició para <strong>${entitlementName}</strong> está activo durante <strong>${activationDuration}</strong>.",
                "L’accès Just-In-Time lancé par ${requestedForIdentityName} pour <strong>${entitlementName}</strong> est actif pour <strong>${activationDuration}</strong>.",
                "L’accesso Just-In-Time avviato da ${requestedForIdentityName} per <strong>${entitlementName}</strong> è attivo per <strong>${activationDuration}</strong>.",
                "Der von ${requestedForIdentityName} gestartete Just-In-Time-Zugriff auf <strong>${entitlementName}</strong> ist jetzt für <strong>${activationDuration}</strong> aktiv.",
                "O acesso Just-In-Time que ${requestedForIdentityName} iniciou para <strong>${entitlementName}</strong> está ativo durante <strong>${activationDuration}</strong>.",
                "أصبح وصول Just-In-Time الذي بدأه ${requestedForIdentityName} لـ <strong>${entitlementName}</strong> نشطًا لمدة <strong>${activationDuration}</strong>.",
            ),
            "contactOwner": CONTACT_OWNER,
        },
        content=f"""
{info("$tx_intro")}
{p("$tx_contactOwner")}
""",
        sample={"activationDuration": "2 hours"},
    ),
    Rewrite(
        key="jit_assignment_converted_to_jit",
        greet=R2,
        subject=(
            "${requestedObjectName} is now Just-In-Time access",
            "${requestedObjectName} es ahora un acceso Just-In-Time",
            "${requestedObjectName} est désormais un accès Just-In-Time",
            "${requestedObjectName} è ora un accesso Just-In-Time",
            "${requestedObjectName} ist jetzt ein Just-In-Time-Zugriff",
            "${requestedObjectName} é agora um acesso Just-In-Time",
            "أصبح ${requestedObjectName} وصول Just-In-Time",
        ),
        strings={
            "intro": (
                "The <strong>${requestedObjectName}</strong> entitlement has been assigned to you as Just-In-Time access.",
                "Se te ha asignado el derecho <strong>${requestedObjectName}</strong> como acceso Just-In-Time.",
                "Le droit d’accès <strong>${requestedObjectName}</strong> vous a été attribué en tant qu’accès Just-In-Time.",
                "Ti è stata assegnata l’autorizzazione <strong>${requestedObjectName}</strong> come accesso Just-In-Time.",
                "Die Berechtigung <strong>${requestedObjectName}</strong> wurde Ihnen als Just-In-Time-Zugriff zugewiesen.",
                "O direito de acesso <strong>${requestedObjectName}</strong> foi-lhe atribuído como acesso Just-In-Time.",
                "تم إسناد الاستحقاق <strong>${requestedObjectName}</strong> إليك كوصول Just-In-Time.",
            ),
            "jit": JIT_NOTE,
        },
        content=f"""
{p("$tx_intro")}
{info("$tx_jit")}
#if($removeDate)
{details([("$tx_endsOn", "${removeDate}")])}
#end
""",
    ),
    Rewrite(
        key="jit_deactivation",
        greet=R2,
        subject=(
            "Your Just-In-Time access to ${entitlementName} has been deactivated",
            "Se ha desactivado tu acceso Just-In-Time a ${entitlementName}",
            "Votre accès Just-In-Time à ${entitlementName} a été désactivé",
            "Il tuo accesso Just-In-Time a ${entitlementName} è stato disattivato",
            "Ihr Just-In-Time-Zugriff auf ${entitlementName} wurde deaktiviert",
            "O seu acesso Just-In-Time a ${entitlementName} foi desativado",
            "تم إلغاء تفعيل وصول Just-In-Time الخاص بك إلى ${entitlementName}",
        ),
        strings={
            "intro": (
                "Your Just-In-Time access to <strong>${entitlementName}</strong> has been deactivated and the access removed.",
                "Tu acceso Just-In-Time a <strong>${entitlementName}</strong> se ha desactivado y se ha retirado el acceso.",
                "Votre accès Just-In-Time à <strong>${entitlementName}</strong> a été désactivé et l’accès retiré.",
                "Il tuo accesso Just-In-Time a <strong>${entitlementName}</strong> è stato disattivato e l’accesso rimosso.",
                "Ihr Just-In-Time-Zugriff auf <strong>${entitlementName}</strong> wurde deaktiviert und entzogen.",
                "O seu acesso Just-In-Time a <strong>${entitlementName}</strong> foi desativado e o acesso removido.",
                "تم إلغاء تفعيل وصول Just-In-Time الخاص بك إلى <strong>${entitlementName}</strong> وإزالة الوصول.",
            ),
            "manage": ("View details", "Ver detalles", "Voir les détails", "Visualizza dettagli", "Details anzeigen", "Ver detalhes", "عرض التفاصيل"),
            "contactOwner": CONTACT_OWNER,
        },
        content=f"""
{p("$tx_intro")}
#if($activationUrl)
{button("$activationUrl", "$tx_manage")}
#end
{p("$tx_contactOwner")}
""",
    ),
    # --------------------------------------------------------- account requests
    Rewrite(
        key="account_request_submitted",
        greet="$data.requesterName",
        subject=(
            "$data.sourceName: $data.operationType request submitted for $data.accountName",
            "$data.sourceName: solicitud de $data.operationType enviada para $data.accountName",
            "$data.sourceName : demande $data.operationType envoyée pour $data.accountName",
            "$data.sourceName: richiesta $data.operationType inviata per $data.accountName",
            "$data.sourceName: Anfrage ($data.operationType) für $data.accountName gesendet",
            "$data.sourceName: pedido de $data.operationType enviado para $data.accountName",
            "$data.sourceName: تم إرسال طلب $data.operationType لـ $data.accountName",
        ),
        strings={
            **ACCOUNT_LABELS,
            "intro": (
                "Your account request was submitted successfully.",
                "Tu solicitud de cuenta se ha enviado correctamente.",
                "Votre demande de compte a bien été envoyée.",
                "La tua richiesta relativa all’account è stata inviata correttamente.",
                "Ihre Kontoanfrage wurde erfolgreich gesendet.",
                "O seu pedido de conta foi enviado com êxito.",
                "تم إرسال طلب الحساب الخاص بك بنجاح.",
            ),
            "next": (
                "You will receive another email when the request is complete.",
                "Recibirás otro correo cuando la solicitud se haya completado.",
                "Vous recevrez un autre e-mail une fois la demande traitée.",
                "Riceverai un’altra e-mail quando la richiesta sarà completata.",
                "Sie erhalten eine weitere E-Mail, sobald die Anfrage abgeschlossen ist.",
                "Receberá outro e-mail quando o pedido estiver concluído.",
                "ستتلقى رسالة أخرى عند اكتمال الطلب.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{details(ACCOUNT_ROWS)}
{p("$tx_next")}
{button(URL2 + "/ui/d/my-requests/account-requests", "$tx_viewRequests")}
""",
        sample=ACCOUNT_SAMPLE,
    ),
    Rewrite(
        key="account_request_failed",
        greet="$data.requesterName",
        subject=(
            "$data.sourceName: $data.operationType request failed for $data.accountName",
            "$data.sourceName: ha fallado la solicitud de $data.operationType para $data.accountName",
            "$data.sourceName : échec de la demande $data.operationType pour $data.accountName",
            "$data.sourceName: richiesta $data.operationType non riuscita per $data.accountName",
            "$data.sourceName: Anfrage ($data.operationType) für $data.accountName fehlgeschlagen",
            "$data.sourceName: falha no pedido de $data.operationType para $data.accountName",
            "$data.sourceName: فشل طلب $data.operationType لـ $data.accountName",
        ),
        strings={
            **ACCOUNT_LABELS,
            "intro": (
                "Your account request could not be completed.",
                "No se ha podido completar tu solicitud de cuenta.",
                "Votre demande de compte n’a pas pu aboutir.",
                "Non è stato possibile completare la tua richiesta relativa all’account.",
                "Ihre Kontoanfrage konnte nicht abgeschlossen werden.",
                "Não foi possível concluir o seu pedido de conta.",
                "تعذّر إكمال طلب الحساب الخاص بك.",
            ),
            "error": ("Error:", "Error:", "Erreur :", "Errore:", "Fehler:", "Erro:", "الخطأ:"),
        },
        content=f"""
{note("$tx_intro")}
{details(ACCOUNT_ROWS)}
{p("<strong>$tx_error</strong>")}
{quote("$data.failureReason")}
{p("$tx_contactAdmin")}
""",
        sample=ACCOUNT_SAMPLE,
    ),
    Rewrite(
        key="account_deletion_request_completed",
        greet="$data.requesterName",
        subject=(
            "$data.sourceName: $data.operationType request completed for $data.accountName",
            "$data.sourceName: solicitud de $data.operationType completada para $data.accountName",
            "$data.sourceName : demande $data.operationType terminée pour $data.accountName",
            "$data.sourceName: richiesta $data.operationType completata per $data.accountName",
            "$data.sourceName: Anfrage ($data.operationType) für $data.accountName abgeschlossen",
            "$data.sourceName: pedido de $data.operationType concluído para $data.accountName",
            "$data.sourceName: اكتمل طلب $data.operationType لـ $data.accountName",
        ),
        strings={
            **ACCOUNT_LABELS,
            "intro": (
                "Your account request was completed successfully. The account has been removed from the source.",
                "Tu solicitud de cuenta se ha completado correctamente. La cuenta se ha eliminado del origen.",
                "Votre demande de compte a bien été traitée. Le compte a été supprimé de la source.",
                "La tua richiesta relativa all’account è stata completata correttamente. L’account è stato rimosso dall’origine.",
                "Ihre Kontoanfrage wurde erfolgreich abgeschlossen. Das Konto wurde aus der Quelle entfernt.",
                "O seu pedido de conta foi concluído com êxito. A conta foi removida da origem.",
                "اكتمل طلب الحساب الخاص بك بنجاح. تمت إزالة الحساب من المصدر.",
            ),
        },
        content=f"""
{info("$tx_intro")}
{details(ACCOUNT_ROWS)}
""",
        sample=ACCOUNT_SAMPLE,
    ),
    # ---------------------------------------------------------------------- SoD
    Rewrite(
        key="sod_conflicts_on_access_request_notification",
        greet="$requesterName",
        subject=(
            "Your access request needs attention",
            "Tu solicitud de acceso requiere atención",
            "Votre demande d’accès requiert votre attention",
            "La tua richiesta di accesso richiede attenzione",
            "Ihre Zugriffsanfrage erfordert Ihre Aufmerksamkeit",
            "O seu pedido de acesso requer atenção",
            "طلب الوصول الخاص بك يحتاج إلى متابعة",
        ),
        prelude="""
#set($emeaItems = "")#set($sep = "")#foreach($item in $accessRequestItems.split(","))#set($emeaItems = "$emeaItems$sep<strong>$item.trim()</strong>")#set($sep = ", ")#end
""",
        strings={
            "intro": (
                "You recently requested access to $emeaItems. We could not send it to your approver yet because of a <strong>separation of duties (SoD) conflict</strong>.",
                "Has solicitado recientemente acceso a $emeaItems. Todavía no hemos podido enviarla a tu aprobador debido a un <strong>conflicto de segregación de funciones (SoD)</strong>.",
                "Vous avez récemment demandé l’accès à $emeaItems. Nous n’avons pas encore pu transmettre la demande à votre approbateur en raison d’un <strong>conflit de séparation des tâches (SoD)</strong>.",
                "Di recente hai richiesto l’accesso a $emeaItems. Non è stato ancora possibile inviare la richiesta al tuo approvatore a causa di un <strong>conflitto di separazione dei compiti (SoD)</strong>.",
                "Sie haben kürzlich Zugriff auf $emeaItems angefordert. Wegen eines <strong>Konflikts bei der Funktionstrennung (SoD)</strong> konnten wir die Anfrage noch nicht an Ihre genehmigende Person senden.",
                "Pediu recentemente acesso a $emeaItems. Ainda não foi possível enviar o pedido ao seu aprovador devido a um <strong>conflito de segregação de funções (SoD)</strong>.",
                "طلبت مؤخرًا الوصول إلى $emeaItems. لم نتمكن من إرساله إلى الموافِق بعد بسبب <strong>تعارض في الفصل بين المهام (SoD)</strong>.",
            ),
            "why": (
                "Some combinations of access are not allowed under the company’s security policy. These SoD rules prevent one person from having too much control over a sensitive process.",
                "La política de seguridad de la empresa no permite algunas combinaciones de acceso. Estas reglas SoD evitan que una sola persona tenga demasiado control sobre un proceso sensible.",
                "Certaines combinaisons d’accès ne sont pas autorisées par la politique de sécurité de l’entreprise. Ces règles SoD empêchent qu’une seule personne ait trop de contrôle sur un processus sensible.",
                "Alcune combinazioni di accessi non sono consentite dalla politica di sicurezza aziendale. Queste regole SoD impediscono che una sola persona abbia troppo controllo su un processo sensibile.",
                "Bestimmte Kombinationen von Zugriffen sind nach der Sicherheitsrichtlinie des Unternehmens nicht zulässig. Diese SoD-Regeln verhindern, dass eine einzelne Person zu viel Kontrolle über einen sensiblen Prozess hat.",
                "Algumas combinações de acessos não são permitidas pela política de segurança da empresa. Estas regras SoD evitam que uma única pessoa tenha demasiado controlo sobre um processo sensível.",
                "لا تسمح سياسة الأمان في الشركة ببعض مجموعات الوصول. تمنع قواعد SoD هذه أي شخص من امتلاك قدر مفرط من السيطرة على عملية حساسة.",
            ),
            "review": ("Review your request", "Revisar tu solicitud", "Examiner votre demande", "Esamina la tua richiesta", "Anfrage prüfen", "Rever o seu pedido", "مراجعة طلبك"),
        },
        content=f"""
{note("$tx_intro")}
{p("$tx_why")}
{details([("$tx_requestedBy", "$accessRequestDetails.requestBy"), ("$tx_requestedFor", "$accessRequestDetails.requestedFor"), ("$tx_date", "$accessRequestDetails.date")])}
{button(URL2 + "/ui/d/my-requests/access-requests", "$tx_review")}
""",
        sample={"accessRequestItems": "FIN-Ledger-Admin, FIN-Payments-Approver", "accessRequestDetails.requestBy": "Ana García", "accessRequestDetails.requestedFor": "Ana García", "accessRequestDetails.date": "Oct 14, 2026"},
    ),
]

# Labels shared by the certification templates.
for _t in TEMPLATES:
    if _t.key in ("certification", "certification_due", "bulk_reassignment"):
        _t.strings.update({"certificationLabel": CERTIFICATION, "dueBy": DUE_BY, "reviewCert": REVIEW_CERT})
