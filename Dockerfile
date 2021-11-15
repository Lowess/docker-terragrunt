FROM hashicorp/terraform:0.13.7

ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
ENV AWS_SDK_LOAD_CONFIG=1 \
    TERRAGRUNT_VERSION=0.26.7 \
    TERRAFORM_PLUGIN_ARCH=linux_amd64 \
    TERRAFORM_PLUGIN_DIR=/opt/.terraform.d/plugins \
    TERRAFORM_PLUGIN_URL=https://releases.hashicorp.com/ \
    TERRAFORM_PLUGINS="\
        aws:3.64.2 \
        grafana:1.5.0 \
        null:2.1.2 \
        postgresql:1.7.1 \
        spotinst:1.27.0 \
        random:2.3.0 \
        template:2.1.2" \
    CREDSTASH_PROVIDER_VERSION=0.4.1 \
    PREFIX=/usr/local/bin \
    PATH="/usr/local/bin:${PATH}"

RUN apk update && \
    apk add coreutils file curl jq vim gnupg groff

# Install Terragrunt
RUN mkdir -p "${PREFIX}" \
    && curl -Lso "${PREFIX}/terragrunt" https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 \
    && chmod -R -c +x "${PREFIX}" \
    && find "${PREFIX}" -type f -print -exec file {} \;

# Terraform Providers (Pre-bake plugins for https://learn.hashicorp.com/terraform/development/running-terraform-in-automation)
RUN mkdir -p "${TERRAFORM_PLUGIN_DIR}/${TERRAFORM_PLUGIN_ARCH}" \
    && curl -Lso "${TERRAFORM_PLUGIN_DIR}/terraform-provider-credstash_${TERRAFORM_PLUGIN_ARCH}" https://github.com/sspinc/terraform-provider-credstash/releases/download/v${CREDSTASH_PROVIDER_VERSION}/terraform-provider-credstash_${TERRAFORM_PLUGIN_ARCH} \
    && for PLUGIN in ${TERRAFORM_PLUGINS}; do \
    curl -Lso "${TERRAFORM_PLUGIN_DIR}/${TERRAFORM_PLUGIN_ARCH}/terraform-provider-${PLUGIN%:*}_${PLUGIN##*:}_${TERRAFORM_PLUGIN_ARCH}.zip" \
            "${TERRAFORM_PLUGIN_URL}terraform-provider-${PLUGIN%:*}/${PLUGIN##*:}/terraform-provider-${PLUGIN%:*}_${PLUGIN##*:}_${TERRAFORM_PLUGIN_ARCH}.zip" \
    && unzip -d "${TERRAFORM_PLUGIN_DIR}/${TERRAFORM_PLUGIN_ARCH}" "${TERRAFORM_PLUGIN_DIR}/${TERRAFORM_PLUGIN_ARCH}/terraform-provider-${PLUGIN%:*}_${PLUGIN##*:}_${TERRAFORM_PLUGIN_ARCH}.zip" \
    && rm "${TERRAFORM_PLUGIN_DIR}/${TERRAFORM_PLUGIN_ARCH}/terraform-provider-${PLUGIN%:*}_${PLUGIN##*:}_${TERRAFORM_PLUGIN_ARCH}.zip" \
    ; done \
    && chmod -R -c a+x "${TERRAFORM_PLUGIN_DIR}" \
    && chmod -R -c a+w "${TERRAFORM_PLUGIN_DIR}/${TERRAFORM_PLUGIN_ARCH}" \
    && find "${TERRAFORM_PLUGIN_DIR}" -type f -print -exec file {} \;


# Install Python and Credstash
RUN apk --no-cache add bash py-pip g++ python3 python3-dev build-base libffi-dev openssl-dev && \
    pip install -U pip \
    pip install cffi==1.14.2 && \
    pip install credstash==1.17.1 && \
    pip install awscli==1.18.223

COPY aliases.sh /etc/profile.d/
COPY .terraformrc /root/.terraformrc
COPY entrypoint.sh /

WORKDIR /terragrunt

ENTRYPOINT ["/entrypoint.sh"]
