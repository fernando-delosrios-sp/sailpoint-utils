"""Identity, sign-in and password templates (version 1: `$user`, `${PRODUCT_NAME}`)."""

from build_templates import Rewrite, bullets, button, code, details, info, li, link_fallback, note, p, tr

PN = "${PRODUCT_NAME}"

_ATTEMPT_LINE = tr((
    "$attempt.count attempts from $attempt.location",
    "$attempt.count intentos desde $attempt.location",
    "$attempt.count tentatives depuis $attempt.location",
    "$attempt.count tentativi da $attempt.location",
    "$attempt.count Versuche von $attempt.location",
    "$attempt.count tentativas a partir de $attempt.location",
    "$attempt.count محاولات من $attempt.location",
))

# --- shared by both password-change templates ------------------------------

_PASSWORD_CHANGE_STRINGS = {
    "appsUpdated": (
        "Your password was updated for these apps, which share the same password:",
        "Tu contraseña se ha actualizado en estas aplicaciones, que comparten la misma contraseña:",
        "Votre mot de passe a été mis à jour pour ces applications, qui partagent le même mot de passe :",
        "La tua password è stata aggiornata per queste app, che condividono la stessa password:",
        "Ihr Kennwort wurde für diese Apps aktualisiert, die dasselbe Kennwort verwenden:",
        "A sua palavra-passe foi atualizada nestas aplicações, que partilham a mesma palavra-passe:",
        "تم تحديث كلمة المرور للتطبيقات التالية التي تشترك في كلمة المرور نفسها:",
    ),
    "changed": (
        "Your $emeaProduct password has been changed.",
        "Tu contraseña de $emeaProduct se ha cambiado.",
        "Votre mot de passe $emeaProduct a été modifié.",
        "La tua password di $emeaProduct è stata modificata.",
        "Ihr $emeaProduct-Kennwort wurde geändert.",
        "A sua palavra-passe do $emeaProduct foi alterada.",
        "تم تغيير كلمة مرور $emeaProduct الخاصة بك.",
    ),
    "appsFailed": (
        "However, your password could not be updated for these apps, which also share it:",
        "Sin embargo, no se ha podido actualizar la contraseña en estas aplicaciones, que también la comparten:",
        "Cependant, votre mot de passe n’a pas pu être mis à jour pour ces applications, qui le partagent également :",
        "Tuttavia, non è stato possibile aggiornare la password per queste app, che la condividono:",
        "Für diese Apps, die das Kennwort ebenfalls verwenden, konnte es jedoch nicht aktualisiert werden:",
        "No entanto, não foi possível atualizar a palavra-passe nestas aplicações, que também a partilham:",
        "لكن تعذّر تحديث كلمة المرور للتطبيقات التالية التي تشترك فيها أيضًا:",
    ),
    "systemsFailed": (
        "Your password could not be updated on the systems that share it.",
        "No se ha podido actualizar la contraseña en los sistemas que la comparten.",
        "Votre mot de passe n’a pas pu être mis à jour sur les systèmes qui le partagent.",
        "Non è stato possibile aggiornare la password sui sistemi che la condividono.",
        "Ihr Kennwort konnte auf den Systemen, die es verwenden, nicht aktualisiert werden.",
        "Não foi possível atualizar a palavra-passe nos sistemas que a partilham.",
        "تعذّر تحديث كلمة المرور على الأنظمة التي تشترك فيها.",
    ),
    "notAttemptedApps": (
        "Because your primary authentication source could not be updated, these apps were not attempted:",
        "Como no se ha podido actualizar tu fuente de autenticación principal, no se ha intentado en estas aplicaciones:",
        "Votre source d’authentification principale n’ayant pas pu être mise à jour, ces applications n’ont pas été traitées :",
        "Poiché non è stato possibile aggiornare la tua origine di autenticazione principale, queste app non sono state elaborate:",
        "Da Ihre primäre Authentifizierungsquelle nicht aktualisiert werden konnte, wurden diese Apps nicht bearbeitet:",
        "Como não foi possível atualizar a sua origem de autenticação principal, estas aplicações não foram processadas:",
        "نظرًا لتعذّر تحديث مصدر المصادقة الأساسي، لم تتم محاولة تحديث هذه التطبيقات:",
    ),
    "notAttemptedSystems": (
        "Because your primary authentication source could not be updated, the other systems that share your password were not attempted.",
        "Como no se ha podido actualizar tu fuente de autenticación principal, no se ha intentado en los demás sistemas que comparten tu contraseña.",
        "Votre source d’authentification principale n’ayant pas pu être mise à jour, les autres systèmes qui partagent votre mot de passe n’ont pas été traités.",
        "Poiché non è stato possibile aggiornare la tua origine di autenticazione principale, gli altri sistemi che condividono la password non sono stati elaborati.",
        "Da Ihre primäre Authentifizierungsquelle nicht aktualisiert werden konnte, wurden die anderen Systeme mit diesem Kennwort nicht bearbeitet.",
        "Como não foi possível atualizar a sua origem de autenticação principal, os outros sistemas que partilham a palavra-passe não foram processados.",
        "نظرًا لتعذّر تحديث مصدر المصادقة الأساسي، لم تتم محاولة تحديث الأنظمة الأخرى التي تشترك في كلمة المرور.",
    ),
    "tryAgain": (
        "<strong>Please try changing your password again.</strong> The change applies to every app and system that shares this password.",
        "<strong>Vuelve a intentar cambiar la contraseña.</strong> El cambio se aplica a todas las aplicaciones y sistemas que la comparten.",
        "<strong>Veuillez réessayer de modifier votre mot de passe.</strong> La modification s’applique à toutes les applications et à tous les systèmes qui le partagent.",
        "<strong>Prova di nuovo a modificare la password.</strong> La modifica si applica a tutte le app e i sistemi che la condividono.",
        "<strong>Bitte ändern Sie Ihr Kennwort erneut.</strong> Die Änderung gilt für alle Apps und Systeme, die dieses Kennwort verwenden.",
        "<strong>Tente alterar a palavra-passe novamente.</strong> A alteração aplica-se a todas as aplicações e sistemas que a partilham.",
        "<strong>يُرجى محاولة تغيير كلمة المرور مرة أخرى.</strong> ينطبق التغيير على كل تطبيق ونظام يشترك في كلمة المرور هذه.",
    ),
}

_PASSWORD_CHANGE_SUBJECT = (
    "#if($sourceFailedCount && $sourceFailedCount > 0)Your password update failed#{else}Your password was updated#end",
    "#if($sourceFailedCount && $sourceFailedCount > 0)No se ha podido actualizar tu contraseña#{else}Tu contraseña se ha actualizado#end",
    "#if($sourceFailedCount && $sourceFailedCount > 0)Échec de la mise à jour de votre mot de passe#{else}Votre mot de passe a été mis à jour#end",
    "#if($sourceFailedCount && $sourceFailedCount > 0)Aggiornamento della password non riuscito#{else}La tua password è stata aggiornata#end",
    "#if($sourceFailedCount && $sourceFailedCount > 0)Kennwortänderung fehlgeschlagen#{else}Ihr Kennwort wurde aktualisiert#end",
    "#if($sourceFailedCount && $sourceFailedCount > 0)Falha na atualização da palavra-passe#{else}A sua palavra-passe foi atualizada#end",
    "#if($sourceFailedCount && $sourceFailedCount > 0)فشل تحديث كلمة المرور#{else}تم تحديث كلمة المرور#end",
)

_PASSWORD_CHANGE_PRELUDE = """
#set($emeaProduct = "${PRODUCT_NAME}")
#set($emeaFailed = false)
#if(($sourceFailedCount && $sourceFailedCount > 0) || ($appFailedCount && $appFailedCount > 0))#set($emeaFailed = true)#end
"""


def _password_change_content(list_apps: bool) -> str:
    """`list_apps`: app lists are collections (app template) rather than preformatted strings."""

    def apps(var: str) -> str:
        if list_apps:
            return bullets(f"#foreach($item in ${var}){li('$item')}#end")
        return p(f"<strong>${var}</strong>")

    not_attempted = (
        f"""
#if($appNotAttemptedCount && $appNotAttemptedCount > 0)
{p("$tx_notAttemptedApps")}
{apps("appNotAttemptedList")}
#elseif($sourceNotAttemptedCount && $sourceNotAttemptedCount > 0)
{p("$tx_notAttemptedSystems")}
#end"""
        if list_apps
        else ""
    )
    return f"""
#if($appCount && $appCount > 0)
{p("$tx_appsUpdated")}
{apps("appList")}
#elseif(!$emeaFailed)
{info("$tx_changed")}
#end
#if($appFailedCount && $appFailedCount > 0)
{p("$tx_appsFailed")}
{apps("appFailedList")}
#elseif($sourceFailedCount && $sourceFailedCount > 0)
{p("$tx_systemsFailed")}
#end{not_attempted}
#if($emeaFailed)
{note("$tx_tryAgain")}
#end
{p("$tx_notYouChange")}
"""


PASSWORD_SAMPLE = {
    "appCount": "int:2",
    "appList": "list:Workday,ServiceNow",
    "appFailedCount": "int:0",
    "sourceCount": "int:1",
    "sourceFailedCount": "int:0",
}

TEMPLATES = [
    Rewrite(
        key="cloud_user_app_password_changed",
        greet="${user.name}",
        subject=_PASSWORD_CHANGE_SUBJECT,
        prelude=_PASSWORD_CHANGE_PRELUDE,
        strings=_PASSWORD_CHANGE_STRINGS,
        content=_password_change_content(list_apps=True),
        sample=PASSWORD_SAMPLE,
    ),
    Rewrite(
        key="cloud_user_password_changed",
        greet="${user.name}",
        subject=_PASSWORD_CHANGE_SUBJECT,
        prelude=_PASSWORD_CHANGE_PRELUDE,
        strings=_PASSWORD_CHANGE_STRINGS,
        content=_password_change_content(list_apps=False),
        sample={**PASSWORD_SAMPLE, "appList": "Workday, ServiceNow"},
    ),
    Rewrite(
        key="cloud_user_authentication_setting_change",
        greet="${user.name}",
        subject=(
            "A security setting on your " + PN + " account was changed",
            "Se ha cambiado un ajuste de seguridad de tu cuenta de " + PN,
            "Un paramètre de sécurité de votre compte " + PN + " a été modifié",
            "È stata modificata un’impostazione di sicurezza del tuo account " + PN,
            "Eine Sicherheitseinstellung Ihres " + PN + "-Kontos wurde geändert",
            "Uma definição de segurança da sua conta " + PN + " foi alterada",
            "تم تغيير أحد إعدادات الأمان في حسابك على " + PN,
        ),
        strings={
            "intro": (
                "A security setting on your " + PN + " account was updated.",
                "Se ha actualizado un ajuste de seguridad de tu cuenta de " + PN + ".",
                "Un paramètre de sécurité de votre compte " + PN + " a été mis à jour.",
                "È stata aggiornata un’impostazione di sicurezza del tuo account " + PN + ".",
                "Eine Sicherheitseinstellung Ihres " + PN + "-Kontos wurde aktualisiert.",
                "Uma definição de segurança da sua conta " + PN + " foi atualizada.",
                "تم تحديث أحد إعدادات الأمان في حسابك على " + PN + ".",
            ),
            "setting": ("Setting", "Ajuste", "Paramètre", "Impostazione", "Einstellung", "Definição", "الإعداد"),
            "changedOn": ("Changed on", "Fecha del cambio", "Modifié le", "Modificata il", "Geändert am", "Alterada em", "تاريخ التغيير"),
            "applies": (
                "The change takes effect the next time you sign in.",
                "El cambio se aplicará la próxima vez que inicies sesión.",
                "La modification prendra effet lors de votre prochaine connexion.",
                "La modifica sarà effettiva al prossimo accesso.",
                "Die Änderung wird bei Ihrer nächsten Anmeldung wirksam.",
                "A alteração entra em vigor no próximo início de sessão.",
                "يسري التغيير في المرة القادمة التي تسجّل فيها الدخول.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{details([("$tx_setting", "${changedSetting}"), ("$tx_changedOn", "${date}")])}
{p("$tx_applies")}
{note("$tx_notYouChange")}
""",
        sample={"changedSetting": "Phone number", "date": "Oct 14, 2026", "hasOrHave": "has", "homeUrl": "https://company24509-poc.identitynow-demo.com"},
    ),
    Rewrite(
        key="cloud_user_forgot_user_name",
        greet="${user.name}",
        subject=(
            "Your " + PN + " username",
            "Tu nombre de usuario de " + PN,
            "Votre nom d’utilisateur " + PN,
            "Il tuo nome utente " + PN,
            "Ihr " + PN + "-Benutzername",
            "O seu nome de utilizador do " + PN,
            "اسم المستخدم الخاص بك في " + PN,
        ),
        strings={
            "intro": (
                "As requested, here is your " + PN + " username:",
                "Este es tu nombre de usuario de " + PN + ", tal como lo has solicitado:",
                "Comme demandé, voici votre nom d’utilisateur " + PN + " :",
                "Come richiesto, ecco il tuo nome utente " + PN + ":",
                "Wie angefordert, hier ist Ihr " + PN + "-Benutzername:",
                "Conforme pedido, este é o seu nome de utilizador do " + PN + ":",
                "بناءً على طلبك، إليك اسم المستخدم الخاص بك في " + PN + ":",
            ),
            "signIn": ("Sign in", "Iniciar sesión", "Se connecter", "Accedi", "Anmelden", "Iniciar sessão", "تسجيل الدخول"),
        },
        content=f"""
{p("$tx_intro")}
{code("${user.uid}")}
{button("${identityNowUrl}", "$tx_signIn")}
{p("$tx_notYouRequest")}
""",
    ),
    Rewrite(
        key="cloud_user_locked_out",
        greet="${user.name}",
        subject=(
            "Your " + PN + " account has been locked",
            "Tu cuenta de " + PN + " se ha bloqueado",
            "Votre compte " + PN + " a été verrouillé",
            "Il tuo account " + PN + " è stato bloccato",
            "Ihr " + PN + "-Konto wurde gesperrt",
            "A sua conta " + PN + " foi bloqueada",
            "تم قفل حسابك على " + PN,
        ),
        strings={
            "intro": (
                "Your " + PN + " account has been locked after several failed sign-in attempts.",
                "Tu cuenta de " + PN + " se ha bloqueado tras varios intentos de inicio de sesión fallidos.",
                "Votre compte " + PN + " a été verrouillé après plusieurs tentatives de connexion infructueuses.",
                "Il tuo account " + PN + " è stato bloccato dopo diversi tentativi di accesso non riusciti.",
                "Ihr " + PN + "-Konto wurde nach mehreren fehlgeschlagenen Anmeldeversuchen gesperrt.",
                "A sua conta " + PN + " foi bloqueada após várias tentativas de início de sessão falhadas.",
                "تم قفل حسابك على " + PN + " بعد عدة محاولات فاشلة لتسجيل الدخول.",
            ),
            "attempts": ("Failed attempts:", "Intentos fallidos:", "Tentatives infructueuses :", "Tentativi non riusciti:", "Fehlgeschlagene Versuche:", "Tentativas falhadas:", "المحاولات الفاشلة:"),
            "lockedOn": ("Locked on", "Bloqueada el", "Verrouillé le", "Bloccato il", "Gesperrt am", "Bloqueada em", "تاريخ القفل"),
            "lockedUntil": ("Locked until", "Bloqueada hasta", "Verrouillé jusqu’au", "Bloccato fino al", "Gesperrt bis", "Bloqueada até", "مقفل حتى"),
            "forgot": (
                "Forgot your password? You can reset it now.",
                "¿Has olvidado tu contraseña? Puedes restablecerla ahora.",
                "Mot de passe oublié ? Vous pouvez le réinitialiser dès maintenant.",
                "Hai dimenticato la password? Puoi reimpostarla subito.",
                "Kennwort vergessen? Sie können es jetzt zurücksetzen.",
                "Esqueceu-se da palavra-passe? Pode repô-la agora.",
                "هل نسيت كلمة المرور؟ يمكنك إعادة تعيينها الآن.",
            ),
            "resetPassword": ("Reset password", "Restablecer contraseña", "Réinitialiser le mot de passe", "Reimposta password", "Kennwort zurücksetzen", "Repor palavra-passe", "إعادة تعيين كلمة المرور"),
            "someoneElse": (
                "If you think someone else tried to use your account, contact your administrator immediately.",
                "Si crees que otra persona ha intentado usar tu cuenta, ponte en contacto con tu administrador de inmediato.",
                "Si vous pensez qu’une autre personne a tenté d’utiliser votre compte, contactez immédiatement votre administrateur.",
                "Se ritieni che qualcun altro abbia tentato di usare il tuo account, contatta immediatamente il tuo amministratore.",
                "Wenn Sie vermuten, dass jemand anderes versucht hat, Ihr Konto zu verwenden, wenden Sie sich umgehend an Ihre Administration.",
                "Se acha que outra pessoa tentou utilizar a sua conta, contacte imediatamente o seu administrador.",
                "إذا كنت تعتقد أن شخصًا آخر حاول استخدام حسابك، فتواصل مع المسؤول فورًا.",
            ),
        },
        content=f"""
{p("$tx_intro")}
#if($attempts && $attempts.size() > 0)
{p("<strong>$tx_attempts</strong>")}
{bullets("#foreach($attempt in $attempts)" + li(_ATTEMPT_LINE) + "#end")}
#end
{details([("$tx_lockedOn", "${timeLocked}"), ("$tx_lockedUntil", "${timeLockedUntil}")])}
#if($passwordResetUrl)
{p("$tx_forgot")}
{button("${passwordResetUrl}", "$tx_resetPassword")}
#end
{note("$tx_someoneElse")}
""",
        sample={"attempts": "list:", "timeLocked": "Oct 14, 2026 09:12", "timeLockedUntil": "Oct 14, 2026 09:42", "passwordResetUrl": "https://company24509-poc.identitynow-demo.com/reset"},
    ),
    Rewrite(
        key="cloud_user_new_account_notification",
        subject=(
            "${source}: account created for ${username}",
            "${source}: cuenta creada para ${username}",
            "${source} : compte créé pour ${username}",
            "${source}: account creato per ${username}",
            "${source}: Konto für ${username} erstellt",
            "${source}: conta criada para ${username}",
            "${source}: تم إنشاء حساب لـ ${username}",
        ),
        strings={
            "intro": (
                "A new account has been created for <strong>${username}</strong> on <strong>${source}</strong>.",
                "Se ha creado una cuenta nueva para <strong>${username}</strong> en <strong>${source}</strong>.",
                "Un nouveau compte a été créé pour <strong>${username}</strong> sur <strong>${source}</strong>.",
                "È stato creato un nuovo account per <strong>${username}</strong> su <strong>${source}</strong>.",
                "Für <strong>${username}</strong> wurde ein neues Konto in <strong>${source}</strong> erstellt.",
                "Foi criada uma nova conta para <strong>${username}</strong> em <strong>${source}</strong>.",
                "تم إنشاء حساب جديد لـ <strong>${username}</strong> على <strong>${source}</strong>.",
            ),
            "system": ("System", "Sistema", "Système", "Sistema", "System", "Sistema", "النظام"),
            "username": ("Username", "Nombre de usuario", "Nom d’utilisateur", "Nome utente", "Benutzername", "Nome de utilizador", "اسم المستخدم"),
            "accessTitle": ("Access granted:", "Acceso concedido:", "Accès accordé :", "Accesso concesso:", "Gewährter Zugriff:", "Acesso concedido:", "الوصول الممنوح:"),
        },
        content=f"""
{p("$tx_intro")}
{details([("$tx_system", "${source}"), ("$tx_username", "${accountUserName}")])}
#if($accountAccess && $accountAccess.size() > 0)
{p("<strong>$tx_accessTitle</strong>")}
{bullets("#foreach($access in $accountAccess)" + li("$access") + "#end")}
#end
{p("$tx_contactAdmin")}
""",
        sample={"source": "Active Directory", "username": "Ana García", "accountUserName": "ana.garcia", "accountAccess": "list:Domain Users,VPN Users"},
    ),
    Rewrite(
        key="cloud_user_password_expiration",
        greet="${user.name}",
        subject=(
            "#if($dayToExpire <= 0)Your ${acctName} password has expired#elseif($dayToExpire == 1)Your ${acctName} password expires tomorrow#{else}Your ${acctName} password expires in ${dayToExpire} days#end",
            "#if($dayToExpire <= 0)Tu contraseña de ${acctName} ha caducado#elseif($dayToExpire == 1)Tu contraseña de ${acctName} caduca mañana#{else}Tu contraseña de ${acctName} caduca en ${dayToExpire} días#end",
            "#if($dayToExpire <= 0)Votre mot de passe ${acctName} a expiré#elseif($dayToExpire == 1)Votre mot de passe ${acctName} expire demain#{else}Votre mot de passe ${acctName} expire dans ${dayToExpire} jours#end",
            "#if($dayToExpire <= 0)La tua password di ${acctName} è scaduta#elseif($dayToExpire == 1)La tua password di ${acctName} scade domani#{else}La tua password di ${acctName} scade tra ${dayToExpire} giorni#end",
            "#if($dayToExpire <= 0)Ihr ${acctName}-Kennwort ist abgelaufen#elseif($dayToExpire == 1)Ihr ${acctName}-Kennwort läuft morgen ab#{else}Ihr ${acctName}-Kennwort läuft in ${dayToExpire} Tagen ab#end",
            "#if($dayToExpire <= 0)A sua palavra-passe de ${acctName} expirou#elseif($dayToExpire == 1)A sua palavra-passe de ${acctName} expira amanhã#{else}A sua palavra-passe de ${acctName} expira dentro de ${dayToExpire} dias#end",
            "#if($dayToExpire <= 0)انتهت صلاحية كلمة مرور ${acctName}#elseif($dayToExpire == 1)تنتهي صلاحية كلمة مرور ${acctName} غدًا#{else}تنتهي صلاحية كلمة مرور ${acctName} خلال ${dayToExpire} أيام#end",
        ),
        strings={
            "expired": (
                "Your <strong>${acctName}</strong> password has expired. Change it now to keep access to your applications.",
                "Tu contraseña de <strong>${acctName}</strong> ha caducado. Cámbiala ahora para no perder el acceso a tus aplicaciones.",
                "Votre mot de passe <strong>${acctName}</strong> a expiré. Modifiez-le dès maintenant pour conserver l’accès à vos applications.",
                "La tua password di <strong>${acctName}</strong> è scaduta. Modificala ora per mantenere l’accesso alle tue applicazioni.",
                "Ihr <strong>${acctName}</strong>-Kennwort ist abgelaufen. Ändern Sie es jetzt, um weiterhin auf Ihre Anwendungen zugreifen zu können.",
                "A sua palavra-passe de <strong>${acctName}</strong> expirou. Altere-a agora para manter o acesso às suas aplicações.",
                "انتهت صلاحية كلمة مرور <strong>${acctName}</strong>. غيّرها الآن للحفاظ على وصولك إلى تطبيقاتك.",
            ),
            "tomorrow": (
                "Your <strong>${acctName}</strong> password expires <strong>tomorrow</strong>. Change it now to avoid losing access.",
                "Tu contraseña de <strong>${acctName}</strong> caduca <strong>mañana</strong>. Cámbiala ahora para no perder el acceso.",
                "Votre mot de passe <strong>${acctName}</strong> expire <strong>demain</strong>. Modifiez-le dès maintenant pour ne pas perdre l’accès.",
                "La tua password di <strong>${acctName}</strong> scade <strong>domani</strong>. Modificala ora per non perdere l’accesso.",
                "Ihr <strong>${acctName}</strong>-Kennwort läuft <strong>morgen</strong> ab. Ändern Sie es jetzt, um den Zugriff nicht zu verlieren.",
                "A sua palavra-passe de <strong>${acctName}</strong> expira <strong>amanhã</strong>. Altere-a agora para não perder o acesso.",
                "تنتهي صلاحية كلمة مرور <strong>${acctName}</strong> <strong>غدًا</strong>. غيّرها الآن لتجنّب فقدان الوصول.",
            ),
            "days": (
                "Your <strong>${acctName}</strong> password expires in <strong>${dayToExpire} days</strong>. Change it now to avoid losing access.",
                "Tu contraseña de <strong>${acctName}</strong> caduca en <strong>${dayToExpire} días</strong>. Cámbiala ahora para no perder el acceso.",
                "Votre mot de passe <strong>${acctName}</strong> expire dans <strong>${dayToExpire} jours</strong>. Modifiez-le dès maintenant pour ne pas perdre l’accès.",
                "La tua password di <strong>${acctName}</strong> scade tra <strong>${dayToExpire} giorni</strong>. Modificala ora per non perdere l’accesso.",
                "Ihr <strong>${acctName}</strong>-Kennwort läuft in <strong>${dayToExpire} Tagen</strong> ab. Ändern Sie es jetzt, um den Zugriff nicht zu verlieren.",
                "A sua palavra-passe de <strong>${acctName}</strong> expira dentro de <strong>${dayToExpire} dias</strong>. Altere-a agora para não perder o acesso.",
                "تنتهي صلاحية كلمة مرور <strong>${acctName}</strong> خلال <strong>${dayToExpire} أيام</strong>. غيّرها الآن لتجنّب فقدان الوصول.",
            ),
            "changePassword": ("Change password", "Cambiar contraseña", "Modifier le mot de passe", "Modifica password", "Kennwort ändern", "Alterar palavra-passe", "تغيير كلمة المرور"),
            "ssoApps": (
                "These applications use your ${acctName} password for single sign-on:",
                "Estas aplicaciones usan tu contraseña de ${acctName} para el inicio de sesión único:",
                "Ces applications utilisent votre mot de passe ${acctName} pour l’authentification unique :",
                "Queste applicazioni usano la password di ${acctName} per il single sign-on:",
                "Diese Anwendungen verwenden Ihr ${acctName}-Kennwort für Single Sign-On:",
                "Estas aplicações utilizam a palavra-passe de ${acctName} para início de sessão único:",
                "تستخدم هذه التطبيقات كلمة مرور ${acctName} لتسجيل الدخول الموحّد:",
            ),
        },
        content=f"""
#if($dayToExpire <= 0)
{note("$tx_expired")}
#elseif($dayToExpire == 1)
{note("$tx_tomorrow")}
#else
{info("$tx_days")}
#end
{button("${resetUrl}", "$tx_changePassword")}
{link_fallback("$tx_copyLink", "${resetUrl}")}
#if($applist)
{p("$tx_ssoApps")}
{p("<strong>${applist}</strong>")}
#end
""",
        sample={"dayToExpire": "int:5", "acctName": "Active Directory", "resetUrl": "https://company24509-poc.identitynow-demo.com/reset", "applist": "Workday, ServiceNow", "appCount": "int:2"},
    ),
    Rewrite(
        key="cloud_user_password_reset_token",
        greet="${user.name}",
        subject=(
            "Your password reset code: ${token}",
            "Tu código para restablecer la contraseña: ${token}",
            "Votre code de réinitialisation du mot de passe : ${token}",
            "Il tuo codice per reimpostare la password: ${token}",
            "Ihr Code zum Zurücksetzen des Kennworts: ${token}",
            "O seu código de reposição da palavra-passe: ${token}",
            "رمز إعادة تعيين كلمة المرور: ${token}",
        ),
        strings={
            "introSource": (
                "We received a request to reset your <strong>${sourcename}</strong> account password.",
                "Hemos recibido una solicitud para restablecer la contraseña de tu cuenta de <strong>${sourcename}</strong>.",
                "Nous avons reçu une demande de réinitialisation du mot de passe de votre compte <strong>${sourcename}</strong>.",
                "Abbiamo ricevuto una richiesta di reimpostazione della password del tuo account <strong>${sourcename}</strong>.",
                "Wir haben eine Anfrage zum Zurücksetzen des Kennworts Ihres <strong>${sourcename}</strong>-Kontos erhalten.",
                "Recebemos um pedido para repor a palavra-passe da sua conta <strong>${sourcename}</strong>.",
                "تلقّينا طلبًا لإعادة تعيين كلمة مرور حسابك في <strong>${sourcename}</strong>.",
            ),
            "introProduct": (
                "We received a request to reset your " + PN + " password.",
                "Hemos recibido una solicitud para restablecer tu contraseña de " + PN + ".",
                "Nous avons reçu une demande de réinitialisation de votre mot de passe " + PN + ".",
                "Abbiamo ricevuto una richiesta di reimpostazione della tua password di " + PN + ".",
                "Wir haben eine Anfrage zum Zurücksetzen Ihres " + PN + "-Kennworts erhalten.",
                "Recebemos um pedido para repor a sua palavra-passe do " + PN + ".",
                "تلقّينا طلبًا لإعادة تعيين كلمة مرورك في " + PN + ".",
            ),
            "enterCode": (
                "If this was you, enter this code in " + PN + " to verify your identity:",
                "Si has sido tú, introduce este código en " + PN + " para verificar tu identidad:",
                "Si vous êtes à l’origine de cette demande, saisissez ce code dans " + PN + " pour vérifier votre identité :",
                "Se sei stato tu, inserisci questo codice in " + PN + " per verificare la tua identità:",
                "Wenn Sie das waren, geben Sie diesen Code in " + PN + " ein, um Ihre Identität zu bestätigen:",
                "Se foi o próprio, introduza este código no " + PN + " para confirmar a sua identidade:",
                "إذا كنت أنت من قدّم الطلب، فأدخل هذا الرمز في " + PN + " للتحقق من هويتك:",
            ),
            "expires": (
                "The code works once and expires on ${expires}.",
                "El código solo se puede usar una vez y caduca el ${expires}.",
                "Ce code n’est utilisable qu’une fois et expire le ${expires}.",
                "Il codice può essere usato una sola volta e scade il ${expires}.",
                "Der Code ist nur einmal gültig und läuft am ${expires} ab.",
                "O código só pode ser utilizado uma vez e expira em ${expires}.",
                "يعمل الرمز مرة واحدة فقط وتنتهي صلاحيته في ${expires}.",
            ),
        },
        content=f"""
#if($sourcename)
{p("$tx_introSource")}
#else
{p("$tx_introProduct")}
#end
{p("$tx_enterCode")}
{code("${token}")}
{p("$tx_expires")}
{note("$tx_notYouRequest")}
""",
    ),
    Rewrite(
        key="cloud_user_unlock_token",
        greet="${user.name}",
        subject=(
            "Your account unlock code: ${token}",
            "Tu código para desbloquear la cuenta: ${token}",
            "Votre code de déverrouillage du compte : ${token}",
            "Il tuo codice per sbloccare l’account: ${token}",
            "Ihr Code zum Entsperren des Kontos: ${token}",
            "O seu código de desbloqueio da conta: ${token}",
            "رمز إلغاء قفل الحساب: ${token}",
        ),
        strings={
            "intro": (
                "We received a request to unlock your " + PN + " account. If this was you, enter this code in " + PN + " to verify your identity:",
                "Hemos recibido una solicitud para desbloquear tu cuenta de " + PN + ". Si has sido tú, introduce este código en " + PN + " para verificar tu identidad:",
                "Nous avons reçu une demande de déverrouillage de votre compte " + PN + ". Si vous en êtes à l’origine, saisissez ce code dans " + PN + " pour vérifier votre identité :",
                "Abbiamo ricevuto una richiesta di sblocco del tuo account " + PN + ". Se sei stato tu, inserisci questo codice in " + PN + " per verificare la tua identità:",
                "Wir haben eine Anfrage zum Entsperren Ihres " + PN + "-Kontos erhalten. Wenn Sie das waren, geben Sie diesen Code in " + PN + " ein, um Ihre Identität zu bestätigen:",
                "Recebemos um pedido para desbloquear a sua conta " + PN + ". Se foi o próprio, introduza este código no " + PN + " para confirmar a sua identidade:",
                "تلقّينا طلبًا لإلغاء قفل حسابك على " + PN + ". إذا كنت أنت من قدّم الطلب، فأدخل هذا الرمز في " + PN + " للتحقق من هويتك:",
            ),
            "expires": (
                "The code works once and expires on ${expires}.",
                "El código solo se puede usar una vez y caduca el ${expires}.",
                "Ce code n’est utilisable qu’une fois et expire le ${expires}.",
                "Il codice può essere usato una sola volta e scade il ${expires}.",
                "Der Code ist nur einmal gültig und läuft am ${expires} ab.",
                "O código só pode ser utilizado uma vez e expira em ${expires}.",
                "يعمل الرمز مرة واحدة فقط وتنتهي صلاحيته في ${expires}.",
            ),
        },
        content=f"""
{p("$tx_intro")}
{code("${token}")}
{p("$tx_expires")}
{note("$tx_notYouRequest")}
""",
    ),
    Rewrite(
        key="cloud_user_unlocked",
        greet="${user.name}",
        subject=(
            "Your " + PN + " account has been unlocked",
            "Tu cuenta de " + PN + " se ha desbloqueado",
            "Votre compte " + PN + " a été déverrouillé",
            "Il tuo account " + PN + " è stato sbloccato",
            "Ihr " + PN + "-Konto wurde entsperrt",
            "A sua conta " + PN + " foi desbloqueada",
            "تم إلغاء قفل حسابك على " + PN,
        ),
        strings={
            "intro": (
                "Your " + PN + " account has been unlocked. You can sign in again.",
                "Tu cuenta de " + PN + " se ha desbloqueado. Ya puedes volver a iniciar sesión.",
                "Votre compte " + PN + " a été déverrouillé. Vous pouvez de nouveau vous connecter.",
                "Il tuo account " + PN + " è stato sbloccato. Puoi accedere di nuovo.",
                "Ihr " + PN + "-Konto wurde entsperrt. Sie können sich wieder anmelden.",
                "A sua conta " + PN + " foi desbloqueada. Já pode voltar a iniciar sessão.",
                "تم إلغاء قفل حسابك على " + PN + ". يمكنك تسجيل الدخول مرة أخرى.",
            ),
            "someoneElse": (
                "If you think someone else tried to use your account, contact your administrator immediately.",
                "Si crees que otra persona ha intentado usar tu cuenta, ponte en contacto con tu administrador de inmediato.",
                "Si vous pensez qu’une autre personne a tenté d’utiliser votre compte, contactez immédiatement votre administrateur.",
                "Se ritieni che qualcun altro abbia tentato di usare il tuo account, contatta immediatamente il tuo amministratore.",
                "Wenn Sie vermuten, dass jemand anderes versucht hat, Ihr Konto zu verwenden, wenden Sie sich umgehend an Ihre Administration.",
                "Se acha que outra pessoa tentou utilizar a sua conta, contacte imediatamente o seu administrador.",
                "إذا كنت تعتقد أن شخصًا آخر حاول استخدام حسابك، فتواصل مع المسؤول فورًا.",
            ),
        },
        content=f"""
{info("$tx_intro")}
{p("$tx_someoneElse")}
""",
    ),
    Rewrite(
        key="cloud_user_verification_token",
        greet="${user.name}",
        subject=(
            "#if($sourcename)${sourcename}: reset your password#{else}" + PN + ": reset your password#end",
            "#if($sourcename)${sourcename}: restablece tu contraseña#{else}" + PN + ": restablece tu contraseña#end",
            "#if($sourcename)${sourcename} : réinitialisez votre mot de passe#{else}" + PN + " : réinitialisez votre mot de passe#end",
            "#if($sourcename)${sourcename}: reimposta la password#{else}" + PN + ": reimposta la password#end",
            "#if($sourcename)${sourcename}: Kennwort zurücksetzen#{else}" + PN + ": Kennwort zurücksetzen#end",
            "#if($sourcename)${sourcename}: reponha a palavra-passe#{else}" + PN + ": reponha a palavra-passe#end",
            "#if($sourcename)${sourcename}: أعِد تعيين كلمة المرور#{else}" + PN + ": أعِد تعيين كلمة المرور#end",
        ),
        strings={
            "introSource": (
                "We received a request to reset your <strong>${sourcename}</strong> account password.",
                "Hemos recibido una solicitud para restablecer la contraseña de tu cuenta de <strong>${sourcename}</strong>.",
                "Nous avons reçu une demande de réinitialisation du mot de passe de votre compte <strong>${sourcename}</strong>.",
                "Abbiamo ricevuto una richiesta di reimpostazione della password del tuo account <strong>${sourcename}</strong>.",
                "Wir haben eine Anfrage zum Zurücksetzen des Kennworts Ihres <strong>${sourcename}</strong>-Kontos erhalten.",
                "Recebemos um pedido para repor a palavra-passe da sua conta <strong>${sourcename}</strong>.",
                "تلقّينا طلبًا لإعادة تعيين كلمة مرور حسابك في <strong>${sourcename}</strong>.",
            ),
            "introProduct": (
                "We received a request to reset your " + PN + " password.",
                "Hemos recibido una solicitud para restablecer tu contraseña de " + PN + ".",
                "Nous avons reçu une demande de réinitialisation de votre mot de passe " + PN + ".",
                "Abbiamo ricevuto una richiesta di reimpostazione della tua password di " + PN + ".",
                "Wir haben eine Anfrage zum Zurücksetzen Ihres " + PN + "-Kennworts erhalten.",
                "Recebemos um pedido para repor a sua palavra-passe do " + PN + ".",
                "تلقّينا طلبًا لإعادة تعيين كلمة مرورك في " + PN + ".",
            ),
            "next": (
                "If this was you, verify your identity and choose a new password:",
                "Si has sido tú, verifica tu identidad y elige una contraseña nueva:",
                "Si vous êtes à l’origine de cette demande, vérifiez votre identité et choisissez un nouveau mot de passe :",
                "Se sei stato tu, verifica la tua identità e scegli una nuova password:",
                "Wenn Sie das waren, bestätigen Sie Ihre Identität und wählen Sie ein neues Kennwort:",
                "Se foi o próprio, confirme a sua identidade e escolha uma nova palavra-passe:",
                "إذا كنت أنت من قدّم الطلب، فتحقّق من هويتك واختر كلمة مرور جديدة:",
            ),
            "resetPassword": ("Reset password", "Restablecer contraseña", "Réinitialiser le mot de passe", "Reimposta password", "Kennwort zurücksetzen", "Repor palavra-passe", "إعادة تعيين كلمة المرور"),
        },
        content=f"""
#if($sourcename)
{p("$tx_introSource")}
#else
{p("$tx_introProduct")}
#end
{p("$tx_next")}
{button("${verificationURL}", "$tx_resetPassword")}
{link_fallback("$tx_copyLink", "${verificationURL}")}
{note("$tx_notYouRequest")}
""",
        sample={"verificationURL": "https://company24509-poc.identitynow-demo.com/verify?t=abc"},
    ),
    Rewrite(
        key="onboarding_password_reset",
        greet="${userDisplayName}",
        subject=(
            "Set your first " + PN + " password",
            "Establece tu primera contraseña de " + PN,
            "Définissez votre premier mot de passe " + PN,
            "Imposta la tua prima password di " + PN,
            "Legen Sie Ihr erstes " + PN + "-Kennwort fest",
            "Defina a sua primeira palavra-passe do " + PN,
            "عيّن أول كلمة مرور لك في " + PN,
        ),
        strings={
            "intro": (
                "Welcome to " + PN + "! To get started, set your password.",
                "¡Te damos la bienvenida a " + PN + "! Para empezar, establece tu contraseña.",
                "Bienvenue dans " + PN + " ! Pour commencer, définissez votre mot de passe.",
                "Ti diamo il benvenuto in " + PN + "! Per iniziare, imposta la tua password.",
                "Willkommen bei " + PN + "! Legen Sie zunächst Ihr Kennwort fest.",
                "Boas-vindas ao " + PN + "! Para começar, defina a sua palavra-passe.",
                "مرحبًا بك في " + PN + "! للبدء، عيّن كلمة المرور.",
            ),
            "username": ("Username", "Nombre de usuario", "Nom d’utilisateur", "Nome utente", "Benutzername", "Nome de utilizador", "اسم المستخدم"),
            "setPassword": ("Set my password", "Establecer mi contraseña", "Définir mon mot de passe", "Imposta la mia password", "Kennwort festlegen", "Definir a minha palavra-passe", "تعيين كلمة المرور"),
            "expires": (
                "This link expires after ${expirationTime} hours.",
                "Este enlace caduca a las ${expirationTime} horas.",
                "Ce lien expire au bout de ${expirationTime} heures.",
                "Questo link scade dopo ${expirationTime} ore.",
                "Dieser Link läuft nach ${expirationTime} Stunden ab.",
                "Esta ligação expira ao fim de ${expirationTime} horas.",
                "تنتهي صلاحية هذا الرابط بعد ${expirationTime} ساعة.",
            ),
            "closing": ("Welcome aboard,", "Te damos la bienvenida,", "Bienvenue parmi nous,", "Ti diamo il benvenuto,", "Herzlich willkommen und viele Grüße", "Seja bem-vindo(a),", "مرحبًا بك معنا،"),
        },
        content=f"""
{p("$tx_intro")}
{details([("$tx_username", "${userName}")])}
{button("${verificationURL}", "$tx_setPassword")}
{link_fallback("$tx_copyLink", "${verificationURL}")}
{p("$tx_expires")}
""",
        sample={"userDisplayName": "Ana García", "userName": "ana.garcia", "verificationURL": "https://company24509-poc.identitynow-demo.com/verify?t=abc", "expirationTime": "48"},
    ),
    Rewrite(
        key="cloud_lifecycle_state_change",
        subject=(
            "Lifecycle state change for ${identityName}",
            "Cambio de estado del ciclo de vida de ${identityName}",
            "Changement d’état du cycle de vie de ${identityName}",
            "Cambio di stato del ciclo di vita di ${identityName}",
            "Lebenszyklusstatus von ${identityName} geändert",
            "Alteração do estado do ciclo de vida de ${identityName}",
            "تغيير حالة دورة الحياة لـ ${identityName}",
        ),
        strings={
            "intro": (
                "The lifecycle state of <strong>${identityName}</strong> has changed.",
                "El estado del ciclo de vida de <strong>${identityName}</strong> ha cambiado.",
                "L’état du cycle de vie de <strong>${identityName}</strong> a changé.",
                "Lo stato del ciclo di vita di <strong>${identityName}</strong> è cambiato.",
                "Der Lebenszyklusstatus von <strong>${identityName}</strong> hat sich geändert.",
                "O estado do ciclo de vida de <strong>${identityName}</strong> foi alterado.",
                "تغيّرت حالة دورة الحياة لـ <strong>${identityName}</strong>.",
            ),
            "identity": ("Identity", "Identidad", "Identité", "Identità", "Identität", "Identidade", "الهوية"),
            "newState": ("New state", "Nuevo estado", "Nouvel état", "Nuovo stato", "Neuer Status", "Novo estado", "الحالة الجديدة"),
        },
        content=f"""
{p("$tx_intro")}
{details([("$tx_identity", "${identityName}"), ("$tx_newState", "$newState")])}
""",
        sample={"identityName": "Ana García", "newState": "active"},
    ),
]
