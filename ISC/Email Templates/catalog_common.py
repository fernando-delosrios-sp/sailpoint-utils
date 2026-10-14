"""Strings shared by every template, and the User Invitation (standard and My Apps versions).

Translations are tuples in LANGUAGES order: en, es, fr, it, de, pt, ar.
Spanish and Italian use the informal register (tú/tu); French, German and Portuguese the formal one.
Portuguese is European Portuguese; Arabic is Modern Standard Arabic.
"""

from build_templates import BLUE, FONT, INK, MAGENTA, MONO, NAVY, Rewrite, Setting, button, details, link_fallback, note, p, section

# Set before every rewritten template's own strings. `$mailName` is the recipient's name.
COMMON = {
    "hello": (
        "Hello $mailName,",
        "Hola, $mailName:",
        "Bonjour $mailName,",
        "Ciao $mailName,",
        "Hallo $mailName,",
        "Olá $mailName,",
        "مرحبًا $mailName،",
    ),
    "closing": (
        "Kind regards,",
        "Un saludo,",
        "Cordialement,",
        "Cordiali saluti,",
        "Freundliche Grüße",
        "Com os melhores cumprimentos,",
        "مع أطيب التحيات،",
    ),
    "footer": (
        "This is an automated message from the ${mailOrgName} identity platform.",
        "Este es un mensaje automático de la plataforma de identidades de ${mailOrgName}.",
        "Ce message automatique a été envoyé par la plateforme d’identités ${mailOrgName}.",
        "Messaggio automatico inviato dalla piattaforma di gestione delle identità di ${mailOrgName}.",
        "Diese Nachricht wurde automatisch von der Identitätsplattform von ${mailOrgName} versendet.",
        "Mensagem automática enviada pela plataforma de identidades de ${mailOrgName}.",
        "هذه رسالة آلية من منصة الهوية لدى ${mailOrgName}.",
    ),
    "needHelp": (
        "Need help? Contact",
        "¿Necesitas ayuda? Escribe a",
        "Besoin d’aide ? Contactez",
        "Serve aiuto? Scrivi a",
        "Brauchen Sie Hilfe? Kontaktieren Sie",
        "Precisa de ajuda? Contacte",
        "هل تحتاج إلى مساعدة؟ تواصل مع",
    ),
    "notYouChange": (
        "If you did not make this change, contact your IT administrator immediately.",
        "Si no has realizado este cambio, ponte en contacto con tu administrador de TI de inmediato.",
        "Si vous n’êtes pas à l’origine de cette modification, contactez immédiatement votre administrateur informatique.",
        "Se non hai effettuato tu questa modifica, contatta immediatamente il tuo amministratore IT.",
        "Wenn Sie diese Änderung nicht vorgenommen haben, wenden Sie sich umgehend an Ihre IT-Administration.",
        "Se não efetuou esta alteração, contacte imediatamente o seu administrador de TI.",
        "إذا لم تُجرِ هذا التغيير، فتواصل مع مسؤول تقنية المعلومات فورًا.",
    ),
    "notYouRequest": (
        "If you did not make this request, contact your IT administrator immediately.",
        "Si no has hecho esta solicitud, ponte en contacto con tu administrador de TI de inmediato.",
        "Si vous n’êtes pas à l’origine de cette demande, contactez immédiatement votre administrateur informatique.",
        "Se non hai effettuato tu questa richiesta, contatta immediatamente il tuo amministratore IT.",
        "Wenn Sie diese Anfrage nicht gestellt haben, wenden Sie sich umgehend an Ihre IT-Administration.",
        "Se não efetuou este pedido, contacte imediatamente o seu administrador de TI.",
        "إذا لم تقدّم هذا الطلب، فتواصل مع مسؤول تقنية المعلومات فورًا.",
    ),
    "contactAdmin": (
        "If you need help, contact your administrator.",
        "Si necesitas ayuda, ponte en contacto con tu administrador.",
        "Si vous avez besoin d’aide, contactez votre administrateur.",
        "Se hai bisogno di aiuto, contatta il tuo amministratore.",
        "Wenn Sie Hilfe benötigen, wenden Sie sich an Ihre Administration.",
        "Se precisar de ajuda, contacte o seu administrador.",
        "إذا احتجت إلى مساعدة، فتواصل مع المسؤول.",
    ),
    "copyLink": (
        "If the button does not work, copy and paste this link into your browser:",
        "Si el botón no funciona, copia y pega este enlace en tu navegador:",
        "Si le bouton ne fonctionne pas, copiez et collez ce lien dans votre navigateur :",
        "Se il pulsante non funziona, copia e incolla questo link nel browser:",
        "Falls die Schaltfläche nicht funktioniert, kopieren Sie diesen Link in Ihren Browser:",
        "Se o botão não funcionar, copie e cole esta ligação no seu navegador:",
        "إذا لم يعمل الزر، فانسخ هذا الرابط والصقه في المتصفح:",
    ),
    "typeRole": ("role", "rol", "rôle", "ruolo", "Rolle", "função", "دور"),
    "typeEntitlement": ("entitlement", "derecho", "droit d’accès", "autorizzazione", "Berechtigung", "direito de acesso", "استحقاق"),
    "typeAccessProfile": ("access profile", "perfil de acceso", "profil d’accès", "profilo di accesso", "Zugriffsprofil", "perfil de acesso", "ملف وصول"),
    "startsOn": ("Starts", "Inicio", "Début", "Inizio", "Beginn", "Início", "يبدأ"),
    "endsOn": ("Ends", "Fin", "Fin", "Fine", "Ende", "Fim", "ينتهي"),
    "requestedBy": ("Requested by", "Solicitado por", "Demandé par", "Richiesto da", "Angefordert von", "Pedido por", "مقدّم الطلب"),
    "requestedFor": ("Requested for", "Solicitado para", "Demandé pour", "Richiesto per", "Angefordert für", "Pedido para", "المستفيد"),
    "access": ("Access", "Acceso", "Accès", "Accesso", "Zugriff", "Acesso", "الوصول"),
    "comment": ("Comment", "Comentario", "Commentaire", "Commento", "Kommentar", "Comentário", "تعليق"),
    "date": ("Date", "Fecha", "Date", "Data", "Datum", "Data", "التاريخ"),
    "statusApproved": ("approved", "aprobada", "approuvée", "approvata", "genehmigt", "aprovado", "تمت الموافقة عليه"),
    "statusDenied": ("denied", "denegada", "refusée", "rifiutata", "abgelehnt", "recusado", "تم رفضه"),
    "statusCancelled": ("cancelled", "cancelada", "annulée", "annullata", "storniert", "cancelado", "تم إلغاؤه"),
    "openSailPoint": ("Open SailPoint", "Abrir SailPoint", "Ouvrir SailPoint", "Apri SailPoint", "SailPoint öffnen", "Abrir o SailPoint", "فتح SailPoint"),
    "reviewNow": ("Review now", "Revisar ahora", "Examiner maintenant", "Esamina ora", "Jetzt prüfen", "Rever agora", "راجِع الآن"),
    "viewRequests": ("View my requests", "Ver mis solicitudes", "Voir mes demandes", "Visualizza le mie richieste", "Meine Anfragen anzeigen", "Ver os meus pedidos", "عرض طلباتي"),
}

# Wrapped default templates keep their own wording and sign-off; only the footer is translated.
WRAP_COMMON = {"footer": COMMON["footer"], "needHelp": COMMON["needHelp"]}

# Velocity that sets `$mailType` to the translated object type ("Role", "Entitlement", else access profile).
OBJECT_TYPE = """
#if($requestedObjectType == "Role")#set($mailType = $tx_typeRole)#elseif($requestedObjectType == "Entitlement")#set($mailType = $tx_typeEntitlement)#else#set($mailType = $tx_typeAccessProfile)#end
"""


# ---------------------------------------------------------------------------
# User Invitation
# ---------------------------------------------------------------------------

_INVITATION_META = {"name": "User Invitation", "description": "Sent to invite a user to your SailPoint products."}
_MONO_SPAN = f'<span style="font-family:{MONO};">{{}}</span>'

# Standard version: SailPoint's default invitation, same content and order, branded and translated.
USER_INVITATION = Rewrite(
    key="user_invitation-custom",
    meta=_INVITATION_META,
    multilingual_subject=True,
    greet="${__recipient.name}",
    subject=(
        "Welcome to $__global.productName",
        "Te damos la bienvenida a $__global.productName",
        "Bienvenue sur $__global.productName",
        "Ti diamo il benvenuto in $__global.productName",
        "Willkommen bei $__global.productName",
        "Boas-vindas ao $__global.productName",
        "مرحبًا بك في $__global.productName",
    ),
    strings={
        "intro": (
            "You have been invited to use $__global.productName to support and advance your organization’s security.",
            "Te han invitado a usar $__global.productName para respaldar y reforzar la seguridad de tu organización.",
            "Vous êtes invité(e) à utiliser $__global.productName pour soutenir et renforcer la sécurité de votre organisation.",
            "Sei stato invitato a usare $__global.productName per supportare e rafforzare la sicurezza della tua organizzazione.",
            "Sie wurden eingeladen, $__global.productName zu nutzen, um die Sicherheit Ihrer Organisation zu unterstützen und zu stärken.",
            "Foi convidado(a) a utilizar o $__global.productName para apoiar e reforçar a segurança da sua organização.",
            "تمت دعوتك لاستخدام $__global.productName لدعم أمن مؤسستك وتعزيزه.",
        ),
        "userLabel": ("Your username", "Tu nombre de usuario", "Votre nom d’utilisateur", "Il tuo nome utente", "Ihr Benutzername", "O seu nome de utilizador", "اسم المستخدم الخاص بك"),
        "cta": ("Register now", "Regístrate ahora", "S’inscrire", "Registrati ora", "Jetzt registrieren", "Registar agora", "سجّل الآن"),
        "signInLater": (
            "Once you have registered, you can use this link to access $__global.productName:",
            "Cuando te hayas registrado, podrás acceder a $__global.productName con este enlace:",
            "Une fois inscrit(e), vous pourrez accéder à $__global.productName avec ce lien\u00a0:",
            "Dopo la registrazione, potrai accedere a $__global.productName da questo link:",
            "Nach der Registrierung erreichen Sie $__global.productName über diesen Link:",
            "Depois de se registar, pode aceder ao $__global.productName através desta ligação:",
            "بعد التسجيل، يمكنك الوصول إلى $__global.productName عبر هذا الرابط:",
        ),
    },
    content=f"""
{p("$tx_intro")}
{details([("$tx_userLabel", _MONO_SPAN.format("${__recipient.alias}"))])}
{button("${registrationUrl}", "$tx_cta")}
{link_fallback("$tx_copyLink", "${registrationUrl}")}
{link_fallback("$tx_signInLater", "${__global.productUrl}")}
""",
)

# My Apps version (EMEA TES Team only): first sign-in through Microsoft My Apps and SailPoint password reset.
# Kept as a variant file; Import-EmailTemplates.ps1 always imports the standard invitation.
MY_APPS_URL = Setting("mailMyAppsUrl", "https://myapps.microsoft.com", "Microsoft My Apps address")
SIGN_IN_DOMAIN = Setting("mailSignInDomain", "emea-tes-team.cloud", "domain of the sign-in email, after the username")

_STEP_ROW = (
    '<tr><td style="width:28px;vertical-align:top;padding:0 14px 14px 0;">'
    f'<div style="width:28px;height:28px;line-height:28px;border-radius:14px;background-color:{NAVY};color:#FFFFFF;'
    f'font-family:{FONT};font-size:13px;font-weight:600;text-align:center;">{{n}}</div></td>'
    f'<td style="vertical-align:top;padding:4px 0 14px 0;font-family:{FONT};font-size:15px;line-height:22px;color:{INK};">$tx_step{{n}}</td></tr>'
)

USER_INVITATION_MY_APPS = Rewrite(
    key="user_invitation-custom",
    variant="my-apps",
    meta=_INVITATION_META,
    settings=(MY_APPS_URL, SIGN_IN_DOMAIN),
    multilingual_subject=True,
    greet="${__recipient.name}",
    prelude=(
        f"""#set($mailMyAppsLink = '<a href="URL" style="color:COLOR;font-weight:600;text-decoration:none;">Microsoft My Apps</a>')"""
        "#set($mailMyAppsLink = $mailMyAppsLink.replace('URL', $mailMyAppsUrl).replace('COLOR', $mailColorAccent))"
    ),
    subject=(
        "Welcome to ${mailOrgName} – your access details",
        "Te damos la bienvenida a ${mailOrgName}: tus datos de acceso",
        "Bienvenue chez ${mailOrgName}\u00a0: vos informations d’accès",
        "Ti diamo il benvenuto in ${mailOrgName}: i tuoi dati di accesso",
        "Willkommen bei ${mailOrgName} – Ihre Zugangsdaten",
        "Boas-vindas a ${mailOrgName}: os seus dados de acesso",
        "مرحبًا بك في ${mailOrgName} – بيانات الوصول الخاصة بك",
    ),
    strings={
        "intro": (
            "Your ${mailOrgName} account is ready. Follow the steps below to sign in for the first time – it only takes a couple of minutes.",
            "Tu cuenta de ${mailOrgName} ya está lista. Sigue estos pasos para iniciar sesión por primera vez; solo te llevará un par de minutos.",
            "Votre compte ${mailOrgName} est prêt. Suivez les étapes ci-dessous pour vous connecter pour la première fois&nbsp;: cela ne prend que quelques minutes.",
            "Il tuo account ${mailOrgName} è pronto. Segui i passaggi qui sotto per accedere per la prima volta: bastano pochi minuti.",
            "Ihr ${mailOrgName}-Konto ist eingerichtet. Folgen Sie den Schritten unten, um sich zum ersten Mal anzumelden – das dauert nur wenige Minuten.",
            "A sua conta ${mailOrgName} está pronta. Siga os passos abaixo para iniciar sessão pela primeira vez; demora apenas alguns minutos.",
            "حسابك في ${mailOrgName} جاهز. اتبع الخطوات أدناه لتسجيل الدخول لأول مرة – لن يستغرق ذلك سوى دقيقتين.",
        ),
        "detailsTitle": ("Your account details", "Datos de tu cuenta", "Vos informations de compte", "I dati del tuo account", "Ihre Kontodaten", "Dados da sua conta", "تفاصيل حسابك"),
        "emailLabel": ("Sign-in email", "Correo de inicio de sesión", "E-mail de connexion", "E-mail di accesso", "Anmelde-E-Mail", "E-mail de início de sessão", "البريد الإلكتروني لتسجيل الدخول"),
        "userLabel": ("Username", "Nombre de usuario", "Nom d’utilisateur", "Nome utente", "Benutzername", "Nome de utilizador", "اسم المستخدم"),
        "stepsTitle": ("First-time sign-in", "Primer inicio de sesión", "Première connexion", "Primo accesso", "Erstanmeldung", "Primeiro início de sessão", "تسجيل الدخول لأول مرة"),
        "step1": (
            "Go to $mailMyAppsLink and enter your sign-in email.",
            "Ve a $mailMyAppsLink e introduce tu correo de inicio de sesión.",
            "Rendez-vous sur $mailMyAppsLink et saisissez votre e-mail de connexion.",
            "Vai su $mailMyAppsLink e inserisci la tua e-mail di accesso.",
            "Öffnen Sie $mailMyAppsLink und geben Sie Ihre Anmelde-E-Mail ein.",
            "Aceda a $mailMyAppsLink e introduza o seu e-mail de início de sessão.",
            "انتقل إلى $mailMyAppsLink وأدخل البريد الإلكتروني لتسجيل الدخول.",
        ),
        "step2": (
            "Select <strong>Forgot my password</strong>. You will be taken to SailPoint self-service password reset.",
            "Selecciona <strong>¿Olvidó su contraseña?</strong> Se abrirá el restablecimiento de contraseña de autoservicio de SailPoint.",
            "Sélectionnez <strong>Mot de passe oublié&nbsp;?</strong> Vous serez redirigé vers la réinitialisation de mot de passe en libre-service de SailPoint.",
            "Seleziona <strong>Password dimenticata?</strong> Verrai indirizzato al ripristino password self-service di SailPoint.",
            "Wählen Sie <strong>Kennwort vergessen?</strong> Sie werden zur Self-Service-Kennwortzurücksetzung von SailPoint weitergeleitet.",
            "Selecione <strong>Esqueceu-se da palavra-passe?</strong> Será redirecionado para a reposição de palavra-passe self-service da SailPoint.",
            "اختر <strong>Forgot my password</strong>. سيتم نقلك إلى خدمة إعادة تعيين كلمة المرور الذاتية في SailPoint.",
        ),
        "step3": (
            "Choose <strong>Reset password</strong> and enter your username.",
            "Elige <strong>Restablecer contraseña</strong> e introduce tu nombre de usuario.",
            "Choisissez <strong>Réinitialiser le mot de passe</strong> et saisissez votre nom d’utilisateur.",
            "Scegli <strong>Reimposta password</strong> e inserisci il tuo nome utente.",
            "Wählen Sie <strong>Kennwort zurücksetzen</strong> und geben Sie Ihren Benutzernamen ein.",
            "Escolha <strong>Repor palavra-passe</strong> e introduza o seu nome de utilizador.",
            "اختر <strong>Reset password</strong> وأدخل اسم المستخدم.",
        ),
        "step4": (
            "Verify your identity with your alternate email address (or your phone, if available) and set a new password.",
            "Verifica tu identidad con tu correo electrónico alternativo (o con tu teléfono, si está disponible) y establece una nueva contraseña.",
            "Vérifiez votre identité à l’aide de votre adresse e-mail secondaire (ou de votre téléphone, si disponible), puis définissez un nouveau mot de passe.",
            "Verifica la tua identità con l’indirizzo e-mail alternativo (o con il telefono, se disponibile) e imposta una nuova password.",
            "Bestätigen Sie Ihre Identität über Ihre alternative E-Mail-Adresse (oder Ihr Telefon, falls verfügbar) und legen Sie ein neues Kennwort fest.",
            "Confirme a sua identidade com o seu endereço de e-mail alternativo (ou com o telemóvel, se disponível) e defina uma nova palavra-passe.",
            "تحقّق من هويتك باستخدام بريدك الإلكتروني البديل (أو هاتفك، إن توفّر) ثم عيّن كلمة مرور جديدة.",
        ),
        "step5": (
            "Sign in to My Apps with your new password. Your dashboard has shortcuts to every ${mailOrgName} system you have access to.",
            "Inicia sesión en My Apps con tu nueva contraseña. Tu panel incluye accesos directos a todos los sistemas de ${mailOrgName} a los que tienes acceso.",
            "Connectez-vous à My Apps avec votre nouveau mot de passe. Votre tableau de bord contient des raccourcis vers tous les systèmes ${mailOrgName} auxquels vous avez accès.",
            "Accedi a My Apps con la nuova password. La tua dashboard contiene i collegamenti a tutti i sistemi ${mailOrgName} a cui hai accesso.",
            "Melden Sie sich mit Ihrem neuen Kennwort bei My Apps an. Ihr Dashboard enthält Verknüpfungen zu allen ${mailOrgName}-Systemen, auf die Sie Zugriff haben.",
            "Inicie sessão no My Apps com a nova palavra-passe. O seu painel contém atalhos para todos os sistemas ${mailOrgName} a que tem acesso.",
            "سجّل الدخول إلى My Apps بكلمة المرور الجديدة. تحتوي لوحتك على اختصارات لكل أنظمة ${mailOrgName} التي يمكنك الوصول إليها.",
        ),
        "cta": ("Open My Apps", "Abrir My Apps", "Ouvrir My Apps", "Apri My Apps", "My Apps öffnen", "Abrir My Apps", "فتح My Apps"),
        "importantTitle": ("Important", "Importante", "Important", "Importante", "Wichtig", "Importante", "مهم"),
        "important": (
            "Always sign in through Microsoft My Apps. Do not use the SailPoint login page.",
            "Inicia sesión siempre a través de Microsoft My Apps. No utilices la página de inicio de sesión de SailPoint.",
            "Connectez-vous toujours via Microsoft My Apps. N’utilisez pas la page de connexion SailPoint.",
            "Accedi sempre tramite Microsoft My Apps. Non utilizzare la pagina di accesso di SailPoint.",
            "Melden Sie sich immer über Microsoft My Apps an. Verwenden Sie nicht die SailPoint-Anmeldeseite.",
            "Inicie sessão sempre através do Microsoft My Apps. Não utilize a página de início de sessão da SailPoint.",
            "سجّل الدخول دائمًا عبر Microsoft My Apps. لا تستخدم صفحة تسجيل الدخول إلى SailPoint.",
        ),
        "closing": ("Welcome aboard,", "Te damos la bienvenida,", "Bienvenue parmi nous,", "Ti diamo il benvenuto,", "Herzlich willkommen und viele Grüße", "Seja bem-vindo(a),", "مرحبًا بك معنا،"),
    },
    content=f"""
{p("$tx_intro")}
{details([("$tx_emailLabel", _MONO_SPAN.format("${__recipient.alias}@${mailSignInDomain}")), ("$tx_userLabel", _MONO_SPAN.format("${__recipient.alias}"))], title="$tx_detailsTitle")}
{section("$tx_stepsTitle")}
<table style="width:100%;border-spacing:0;border-collapse:separate;">
{"".join(_STEP_ROW.format(n=n) + chr(10) for n in range(1, 6))}</table>
{button("${mailMyAppsUrl}", "$tx_cta")}
{note(f'<strong style="color:{MAGENTA};">$tx_importantTitle:</strong> $tx_important')}
""",
)

TEMPLATES = [USER_INVITATION]
VARIANTS = [USER_INVITATION_MY_APPS]
