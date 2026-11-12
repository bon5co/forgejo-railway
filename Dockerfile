# Forgejo for Railway.
#
# Forgejo (forgejo/forgejo, GPL-3.0) is a self-hosted git forge: git over HTTPS, a REST API, issues, pull requests,
# packages and Actions. A stock container is not usable by an agent that deploys it unattended. It boots into the
# web install wizard, which any visitor can complete (choosing the database and creating the administrator),
# registration is open, it listens on 3000 whatever PORT says, and the only way to obtain a credential is to sign in
# through the browser.
#
# This wrapper (1) bakes the install lock, so there is no wizard to finish, (2) closes registration and makes new
# repositories private, (3) turns the SSH server off (Railway cannot give a service both a TCP proxy and an HTTP
# healthcheck, so git is served over HTTPS), (4) listens on $PORT and derives the public URL from the Railway domain,
# and (5) runs a one-shot s6 service that, once the server answers, creates the administrator from
# FORGEJO_ADMIN_PASSWORD or resets its password to that value. The forge is otherwise untouched.
FROM data.forgejo.org/forgejo/forgejo:17.0.1@sha256:fcd19ff4ebc85fb098a67e8e1d0d5a84d07dd6e8a23edcfdfd5b71a6178953be

ENV INSTALL_LOCK=true \
    DISABLE_REGISTRATION=true \
    DISABLE_SSH=true \
    DB_TYPE=sqlite3 \
    FORGEJO_ADMIN_USER=forgejo-admin \
    FORGEJO_ADMIN_EMAIL=forgejo-admin@example.com

COPY --chmod=0755 railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY --chmod=0755 bootstrap/run /etc/s6/bootstrap/run

EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["/usr/bin/s6-svscan", "/etc/s6"]
