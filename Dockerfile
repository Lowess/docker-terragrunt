FROM hashicorp/terraform:0.12.24

ENV AWS_SDK_LOAD_CONFIG=1 \
    TERRAGRUNT_VERSION=0.23.10 \
    CREDSTASH_PROVIDER_VERSION=0.4.1 \
    PREFIX=/opt/terragrunt \
    PATH="/opt/terragrunt:${PATH}"

RUN apk update && \
    apk add coreutils file curl jq vim

# Install Terragrunt / Terraform Providers
RUN mkdir -p "${PREFIX}" \
    && curl -Lso "${PREFIX}/terragrunt" https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
    && curl -Lso "${PREFIX}/terraform-provider-credstash_linux_amd64" https://github.com/sspinc/terraform-provider-credstash/releases/download/v${CREDSTASH_PROVIDER_VERSION}/terraform-provider-credstash_linux_amd64 \
    && chmod -R -c +x "${PREFIX}" /usr/local/bin \
    && find "${PREFIX}" /usr/local/bin -type f -print -exec file {} \;

# Install Python and Credstash
RUN apk --no-cache add bash py-pip python python-dev python3 python3-dev build-base libffi-dev openssl-dev && \
    pip install cffi==1.11.3 && \
    pip install credstash==1.14.0 && \
    pip install awscli==1.18.45

COPY aliases.sh /etc/profile.d/
COPY .terraformrc /root/.terraformrc
COPY entrypoint.sh /

WORKDIR /terragrunt

ENTRYPOINT ["/entrypoint.sh"]
