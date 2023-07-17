#!/usr/bin/env bash
set -e
set -o pipefail

### Requirements
### ----------------------------------------
### Minimum: (wget or curl) and unzip
### v1: Python v2.7+ or 3.4+
### v2: Nothing special
### ----------------------------------------

### Usage
### ----------------------------------------
### Set AWS_CLI_VERSION env var or pass arg
### Print ls - export VERBOSE=true
### ./entrypoint.sh "$AWS_CLI_VERSION"
### ./entrypoint.sh "$AWS_CLI_VERSION" "$AWS_CLI_ARCH"
### ----------------------------------------


### Functions
msg_error(){
    local msg="$1"
    echo -e "[ERROR] $(date) :: $msg"
    exit 1
}


msg_log(){
    local msg="$1"
    echo -e "[LOG] $(date) :: $msg"
}


set_workdir(){
    local workdir
    workdir="$1"
    mkdir -p "$workdir"
    cd "$workdir"
}


validate_semantic_version(){
    local provided_version
    provided_version="$1"
    msg_log "Validating semantic version - ${provided_version}"
    if [[ "$provided_version" =~ ^([1,2]|[1,2](\.[0-9]{1,2}\.[0-9]{1,3}))$ ]]; then
        msg_log "Valid version input"
    else
        msg_error "Invalid version input \"${provided_version}\", should match: ^([1,2]|[1,2](\.[0-9]{1,2}\.[0-9]{1,3}))$"
    fi
}

install_gpg(){
    apt-get install gpg
}

install_awscli_gpg_key(){
    echo "-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBF2Cr7UBEADJZHcgusOJl7ENSyumXh85z0TRV0xJorM2B/JL0kHOyigQluUG
ZMLhENaG0bYatdrKP+3H91lvK050pXwnO/R7fB/FSTouki4ciIx5OuLlnJZIxSzx
PqGl0mkxImLNbGWoi6Lto0LYxqHN2iQtzlwTVmq9733zd3XfcXrZ3+LblHAgEt5G
TfNxEKJ8soPLyWmwDH6HWCnjZ/aIQRBTIQ05uVeEoYxSh6wOai7ss/KveoSNBbYz
gbdzoqI2Y8cgH2nbfgp3DSasaLZEdCSsIsK1u05CinE7k2qZ7KgKAUIcT/cR/grk
C6VwsnDU0OUCideXcQ8WeHutqvgZH1JgKDbznoIzeQHJD238GEu+eKhRHcz8/jeG
94zkcgJOz3KbZGYMiTh277Fvj9zzvZsbMBCedV1BTg3TqgvdX4bdkhf5cH+7NtWO
lrFj6UwAsGukBTAOxC0l/dnSmZhJ7Z1KmEWilro/gOrjtOxqRQutlIqG22TaqoPG
fYVN+en3Zwbt97kcgZDwqbuykNt64oZWc4XKCa3mprEGC3IbJTBFqglXmZ7l9ywG
EEUJYOlb2XrSuPWml39beWdKM8kzr1OjnlOm6+lpTRCBfo0wa9F8YZRhHPAkwKkX
XDeOGpWRj4ohOx0d2GWkyV5xyN14p2tQOCdOODmz80yUTgRpPVQUtOEhXQARAQAB
tCFBV1MgQ0xJIFRlYW0gPGF3cy1jbGlAYW1hem9uLmNvbT6JAlQEEwEIAD4WIQT7
Xbd/1cEYuAURraimMQrMRnJHXAUCXYKvtQIbAwUJB4TOAAULCQgHAgYVCgkICwIE
FgIDAQIeAQIXgAAKCRCmMQrMRnJHXJIXEAChLUIkg80uPUkGjE3jejvQSA1aWuAM
yzy6fdpdlRUz6M6nmsUhOExjVIvibEJpzK5mhuSZ4lb0vJ2ZUPgCv4zs2nBd7BGJ
MxKiWgBReGvTdqZ0SzyYH4PYCJSE732x/Fw9hfnh1dMTXNcrQXzwOmmFNNegG0Ox
au+VnpcR5Kz3smiTrIwZbRudo1ijhCYPQ7t5CMp9kjC6bObvy1hSIg2xNbMAN/Do
ikebAl36uA6Y/Uczjj3GxZW4ZWeFirMidKbtqvUz2y0UFszobjiBSqZZHCreC34B
hw9bFNpuWC/0SrXgohdsc6vK50pDGdV5kM2qo9tMQ/izsAwTh/d/GzZv8H4lV9eO
tEis+EpR497PaxKKh9tJf0N6Q1YLRHof5xePZtOIlS3gfvsH5hXA3HJ9yIxb8T0H
QYmVr3aIUes20i6meI3fuV36VFupwfrTKaL7VXnsrK2fq5cRvyJLNzXucg0WAjPF
RrAGLzY7nP1xeg1a0aeP+pdsqjqlPJom8OCWc1+6DWbg0jsC74WoesAqgBItODMB
rsal1y/q+bPzpsnWjzHV8+1/EtZmSc8ZUGSJOPkfC7hObnfkl18h+1QtKTjZme4d
H17gsBJr+opwJw/Zio2LMjQBOqlm3K1A4zFTh7wBC7He6KPQea1p2XAMgtvATtNe
YLZATHZKTJyiqA==
=vYOk
-----END PGP PUBLIC KEY BLOCK-----" > /tmp/awscli.gpg
    gpg --import /tmp/awscli.gpg
    rm -f /tmp/awscli.gpg
}

get_signature_url(){
    local download_url
    local signature_url=""
    signature_url="${download_url}.sig"
    echo "$signature_url"
}

get_download_url(){
    local provided_version
    local provided_arch
    local adjusted_arch=""
    local download_url=""
    provided_version="$1"
    provided_arch="$2"
    # v1
    if [[ "$provided_version" =~ ^1.*$ ]]; then
        [[ "$provided_arch" != "amd64" ]] && msg_error "AWS CLI v1 does not support ${_AWS_CLI_VERSION}"
        if [[ "$provided_version" = "1" ]]; then
            download_url="https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
        else
            download_url="https://s3.amazonaws.com/aws-cli/awscli-bundle-${provided_version}.zip"
        fi
    # v2
    elif [[ "$provided_version" =~ ^2.*$ ]]; then
        # Check arch
        if [[ "$provided_arch" = "amd64" ]]; then
            adjusted_arch="x86_64"
        elif [[ "$provided_arch" = "arm64" ]]; then
            adjusted_arch="aarch64"
        else
            echo "Invalid arch - ${provided_arch}"
        fi

        if [[ $provided_version = "2" ]]; then
            # Latest v2
            download_url="https://awscli.amazonaws.com/awscli-exe-linux-${adjusted_arch}.zip"
        else
            # Specific v2
            download_url="https://awscli.amazonaws.com/awscli-exe-linux-${adjusted_arch}-${provided_version}.zip"
        fi
    fi
    echo "$download_url"
}

set_download_tool(){
    # Default is "wget", fallback is "curl", fails otherwise
    if which wget 1>/dev/null; then
        _AWS_CLI_DOWNLOAD_TOOL="wget"
    elif which curl 1>/dev/null; then
        _AWS_CLI_DOWNLOAD_TOOL="curl"
    else
        msg_error "Both 'wget' and 'curl' are not installed"
    fi
}


check_version_exists(){
    local provided_url
    local response=""
    local exists=""
    provided_url="$1"
    [[ "$_VERBOSE" = "true" ]] && msg_log "Checking if the provided version exists in AWS"
    
    if [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "wget" ]]; then
        response="$(wget -q -S --spider "$provided_url" 2>&1 || true)"
    elif [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "curl" ]]; then
        response="$(curl -I -sL "$provided_url" 2>&1 || true)"
    fi

    exists="$(echo "$response" | grep 'HTTP/1.1 200 OK' || true)"
    # If exists is not empty then everything is ok, otherwise should fail and print resposne message
    if [[ -n "$exists" ]]; then
        msg_log "Provided version exists - ${provided_url}"
    else
        msg_error "Provided version does not exist - ${provided_url}\nResponse message:\n${response}"
    fi
}


download_aws_cli(){
    local provided_filename
    local provided_url
    provided_filename="$1"
    provided_url="$2"
    msg_log "Downloading with ${_AWS_CLI_DOWNLOAD_TOOL} ..."

    if [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "wget" ]]; then
        wget -q -O "$provided_filename" "$provided_url"
    elif [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "curl" ]]; then
        curl -sL -o "$provided_filename" "$provided_url"
    fi

    [[ "$_VERBOSE" = "true" ]] && ls -lah "$provided_filename"
    wait
}

download_aws_cli_signature(){
    local provided_filename
    local provided_url
    provided_filename="$1"
    provided_url="$2"
    msg_log "Downloading signature with ${_AWS_CLI_DOWNLOAD_TOOL} ..."

    if [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "wget" ]]; then
        wget -q -O "$provided_filename" "$provided_url"
    elif [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "curl" ]]; then
        curl -sL -o "$provided_filename" "$provided_url"
    fi

    [[ "$_VERBOSE" = "true" ]] && ls -lah "$provided_filename"
    wait
}


install_aws_cli(){
    local provided_filename
    local provided_version
    local provided_arch
    provided_filename="$1"
    provided_version="$2"
    provided_arch="$3"
    msg_log "Unzipping ${provided_filename}"
    unzip -qq "$provided_filename"
    [[ "$_VERBOSE" = "true" ]] && ls -lah
    wait
    msg_log "Installing AWS CLI - ${provided_version}"
    if [[ "$provided_version" =~ ^1.*$ ]]; then
        ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
    elif [[ "$provided_version" =~ ^2.*$ ]]; then
        local aws_path=""
        aws_path=$(which aws || true)
        [[ -n "$aws_path" ]] && msg_log "aws_path = ${aws_path}"
        if [[ "$aws_path" =~ ^qemu-aarch64.* ]]; then
            msg_error "Failed to install AWS CLI - Make sure AWS_CLI_ARCH is set properly, current value is ${provided_arch}"
        elif [[ "$aws_path" =~ ^.*aws.*not.*found || -z "$aws_path" ]]; then
            # Fresh install
            ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
        else
            # Update
            ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
        fi
    fi
    msg_log "Installation completed"
}


cleanup(){
    local workdir
    workdir="$1"
    [[ -d "$workdir" ]] && rm -r "$workdir"
    wait
}


test_aws_cli(){
    local provided_arch
    local test_results
    provided_arch="$1"
    msg_log "Printing AWS CLI installed version"
    test_results="$(aws --version 2>&1 || true)"
    if [[ "$test_results" =~ ^aws-cli/.*  ]]; then
        echo "$test_results"
    else
        msg_error "Installation failed - ${test_results}"
        if [[ "$test_results" =~ ^qemu-aarch64.*Could.*not.*open ]]; then
            msg_log "Make sure AWS_CLI_ARCH is set properly, current value is - ${provided_arch}"
        fi        
    fi
}


install_lightsailctl(){
    local provided_version
    provided_version="$1"
    if [[ $provided_version =~ ^2.*$ ]]; then
        msg_log "Installing Lightsailctl"
        if [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "wget" ]]; then
            wget -q -O "/usr/local/bin/lightsailctl" "https://s3.us-west-2.amazonaws.com/lightsailctl/latest/linux-amd64/lightsailctl"
        elif [[ "$_AWS_CLI_DOWNLOAD_TOOL" = "curl" ]]; then
            curl -sL -o "/usr/local/bin/lightsailctl"  "https://s3.us-west-2.amazonaws.com/lightsailctl/latest/linux-amd64/lightsailctl"
        fi
        wait
        chmod +x /usr/local/bin/lightsailctl
        msg_log "Installation complete"
    else
        msg_error "Cannot install Lightsail plugin with CLI 1.x"
    fi
}


test_lightsailctl(){
    local installed_lightsail
    installed_lightsail=$(lightsailctl 2>&1 | grep "it is meant to be invoked by AWS CLI" || true)
    if [[ -n "$installed_lightsail" ]]; then
        msg_log "Lightsail was installed successfully"
    else
        error_msg "Failed to install lightsailctl"
    fi
}


### Global Variables
msg_log "Provided ROOTDIR: ${ROOT_DIR}"
_ROOT_DIR="${ROOT_DIR:-$PWD}"
msg_log "Provided WORKDIR: ${WORKDIR}"
_WORKDIR="${WORKDIR:-${_ROOT_DIR}/unfor19-awscli}"
msg_log "Final WORKDIR path: ${_WORKDIR}"

_DOWNLOAD_FILENAME="unfor19-awscli.zip"
_VERBOSE=${VERBOSE:-"false"}
_LIGHTSAIL_INSTALL=${LIGHTSAILCTL:-"false"}
_DOWNLOAD_URL=""

_DEFAULT_VERSION="2"
_AWS_CLI_VERSION="${1:-"$AWS_CLI_VERSION"}"   # Use env or arg
_AWS_CLI_VERSION="${_AWS_CLI_VERSION^^}"      # All uppercase
_AWS_CLI_VERSION="${_AWS_CLI_VERSION//"V"/}"  # Remove "V"
_AWS_CLI_VERSION="${_AWS_CLI_VERSION:-"$_DEFAULT_VERSION"}"

_DEFAULT_ARCH="amd64"
_AWS_CLI_ARCH="${2:-"$AWS_CLI_ARCH"}"         # Use env or arg
_AWS_CLI_ARCH="${_AWS_CLI_ARCH,,}"            # All lowercase
_AWS_CLI_ARCH="${_AWS_CLI_ARCH:-"$_DEFAULT_ARCH"}"


### Main
set_workdir "$_WORKDIR"
validate_semantic_version "$_AWS_CLI_VERSION"
set_download_tool

# Install GPG and AWS CLI Signing Key
msg_log "Installing GPG"
# install_gpg
msg_log "Installing AWS CLI Signing Key"
install_awscli_gpg_key

# Set Download URL and check if file exists on server
_AWS_CLI_DOWNLOAD_URL="${AWS_CLI_DOWNLOAD_URL:-"$(get_download_url "$_AWS_CLI_VERSION" "$_AWS_CLI_ARCH" 2>&1)"}"
[[ ! "$_AWS_CLI_DOWNLOAD_URL" =~ ^https://.* ]] && msg_error "$_AWS_CLI_DOWNLOAD_URL"
check_version_exists "$_AWS_CLI_DOWNLOAD_URL"

# Download and install AWS CLI
download_aws_cli "$_DOWNLOAD_FILENAME" "$_AWS_CLI_DOWNLOAD_URL"

# Download CLI signature
download_aws_cli_signature "${_DOWNLOAD_FILENAME}.sig" "${_AWS_CLI_DOWNLOAD_URL}.sig"

gpg --verify "${$_DOWNLOAD_FILENAME}".sig $_DOWNLOAD_FILENAME

install_aws_cli "$_DOWNLOAD_FILENAME" "$_AWS_CLI_VERSION" "$_AWS_CLI_ARCH"
test_aws_cli "$_AWS_CLI_ARCH"

# Optional - Install Lightsail plugin
if [[ "$_LIGHTSAIL_INSTALL" = "true" ]]; then
    install_lightsailctl "$_AWS_CLI_VERSION"
    test_lightsailctl
fi

# Cleanup
cleanup "$_WORKDIR"
