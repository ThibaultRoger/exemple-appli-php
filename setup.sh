#!/usr/bin/env bash
set -e

mkdir -p \
  bin \
  config \
  src/App/Command \
  src/Core/Application/Ports \
  src/Core/Application/UseCase \
  src/Core/Domain/ValueObject \
  src/Core/Domain/Validation \
  src/Core/Domain \
  src/Infrastructure/FileSystem \
  src/Infrastructure/Logger \
  docker/php \
  data/input \
  var/log

#####################
# composer.json
#####################
cat > composer.json <<'JSON'
{
  "name": "cogep/company-json-validator",
  "description": "Validation de fichiers JSON d'entreprises (Clean Architecture, Symfony DI).",
  "type": "project",
  "require": {
    "php": "^8.3",
    "symfony/console": "^7.1",
    "symfony/dependency-injection": "^7.1",
    "symfony/config": "^7.1",
    "monolog/monolog": "^3.0",
    "psr/log": "^3.0"
  },
  "autoload": {
    "psr-4": {
      "App\\": "src/"
    }
  },
  "require-dev": {
    "phpunit/phpunit": "^11.0"
  },
  "minimum-stability": "stable",
  "license": "proprietary"
}
JSON

#####################
# bin/console
#####################
cat > bin/console <<'PHP'
#!/usr/bin/env php
<?php

declare(strict_types=1);

use App\App\Command\ValidateCompaniesCommand;
use Symfony\Component\Config\FileLocator;
use Symfony\Component\Console\Application;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\PhpFileLoader;

require __DIR__ . '/../vendor/autoload.php';

$containerBuilder = new ContainerBuilder();

$loader = new PhpFileLoader(
    $containerBuilder,
    new FileLocator(__DIR__ . '/../config')
);
$loader->load('services.php');

$containerBuilder->compile();

/** @var ValidateCompaniesCommand $command */
$command = $containerBuilder->get(ValidateCompaniesCommand::class);

$application = new Application('Company JSON Validator', '1.0.0');
$application->add($command);
$application->setDefaultCommand($command->getName(), true);

$application->run();
PHP

chmod +x bin/console

#####################
# config/services.php
#####################
cat > config/services.php <<'PHP'
<?php

declare(strict_types=1);

use App\App\Command\ValidateCompaniesCommand;
use App\Core\Application\Ports\CompanyFileReaderInterface;
use App\Core\Application\Ports\CompanyValidationLoggerInterface;
use App\Infrastructure\FileSystem\JsonCompanyFileReader;
use App\Infrastructure\Logger\JsonFileCompanyValidationLogger;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;

return function (ContainerConfigurator $configurator): void {
    $services = $configurator->services()
        ->defaults()
        ->autowire()
        ->autoconfigure();

    // Autowire tout le code App\
    $services
        ->load('App\\', __DIR__ . '/../src/*');

    // Bind des interfaces vers les implémentations concrètes
    $services->set(CompanyFileReaderInterface::class, JsonCompanyFileReader::class);
    $services->set(CompanyValidationLoggerInterface::class, JsonFileCompanyValidationLogger::class);

    // Commande principale
    $services->set(ValidateCompaniesCommand::class)
        ->arg('$defaultDirectory', '%kernel.project_dir%/data/input')
        ->public();

    // Paramètre project_dir
    $configurator->parameters()
        ->set('kernel.project_dir', realpath(__DIR__ . '/..'));
};
PHP

#####################
# src/App/Command/ValidateCompaniesCommand.php
#####################
cat > src/App/Command/ValidateCompaniesCommand.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\App\Command;

use App\Core\Application\UseCase\ValidateCompanyFileUseCase;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(
    name: 'app:validate:companies',
    description: 'Valide les fichiers JSON contenant des entreprises et génère des logs succès/erreur.'
)]
final class ValidateCompaniesCommand extends Command
{
    public function __construct(
        private readonly ValidateCompanyFileUseCase $useCase,
        private readonly string $defaultDirectory = 'data/input'
    ) {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this
            ->addArgument(
                'path',
                InputArgument::OPTIONAL,
                'Chemin vers un fichier JSON ou un répertoire contenant des fichiers JSON',
                $this->defaultDirectory
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        /** @var string $path */
        $path = $input->getArgument('path');

        if (is_dir($path)) {
            $output->writeln(sprintf('<info>Scanning directory "%s"</info>', $path));

            $files = glob(rtrim($path, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . '*.json') ?: [];

            if ($files === []) {
                $output->writeln('<comment>Aucun fichier .json trouvé.</comment>');
                return Command::SUCCESS;
            }

            foreach ($files as $file) {
                $this->processFile($file, $output);
            }

            return Command::SUCCESS;
        }

        if (is_file($path)) {
            $this->processFile($path, $output);
            return Command::SUCCESS;
        }

        $output->writeln(sprintf('<error>Chemin "%s" introuvable</error>', $path));

        return Command::FAILURE;
    }

    private function processFile(string $file, OutputInterface $output): void
    {
        $output->writeln(sprintf('<info>Processing file: %s</info>', $file));

        try {
            $this->useCase->execute($file);
            $output->writeln('<info>✔ Logs générés.</info>');
        } catch (\Throwable $e) {
            $output->writeln(sprintf(
                '<error>Erreur lors du traitement du fichier "%s": %s</error>',
                $file,
                $e->getMessage()
            ));
        }
    }
}
PHP

#####################
# Ports
#####################
cat > src/Core/Application/Ports/CompanyFileReaderInterface.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

interface CompanyFileReaderInterface
{
    /**
     * @return array<int, array<string, mixed>>  Liste brute des enregistrements JSON
     */
    public function read(string $filePath): array;
}
PHP

cat > src/Core/Application/Ports/CompanyValidationLoggerInterface.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Application\Ports;

use App\Core\Domain\Company;
use App\Core\Domain\Validation\CompanyValidationError;

interface CompanyValidationLoggerInterface
{
    /**
     * @param Company[]                 $validCompanies
     * @param array<int, array{
     *   raw: array<string, mixed>,
     *   errors: CompanyValidationError[]
     * }> $invalidCompanies
     */
    public function logFileResult(
        string $filePath,
        array $validCompanies,
        array $invalidCompanies
    ): void;
}
PHP

#####################
# UseCase
#####################
cat > src/Core/Application/UseCase/ValidateCompanyFileUseCase.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Application\UseCase;

use App\Core\Application\Ports\CompanyFileReaderInterface;
use App\Core\Application\Ports\CompanyValidationLoggerInterface;
use App\Core\Domain\Validation\CompanyValidator;

final class ValidateCompanyFileUseCase
{
    public function __construct(
        private CompanyFileReaderInterface $fileReader,
        private CompanyValidator $validator,
        private CompanyValidationLoggerInterface $logger
    ) {
    }

    public function execute(string $filePath): void
    {
        $rawCompanies = $this->fileReader->read($filePath);

        $validCompanies   = [];
        $invalidCompanies = [];

        foreach ($rawCompanies as $rawCompany) {
            $result = $this->validator->validate($rawCompany);

            if ($result['company'] !== null) {
                $validCompanies[] = $result['company'];
                continue;
            }

            $invalidCompanies[] = [
                'raw'    => $rawCompany,
                'errors' => $result['errors'],
            ];
        }

        $this->logger->logFileResult(
            $filePath,
            $validCompanies,
            $invalidCompanies
        );
    }
}
PHP

#####################
# Domain ValueObjects
#####################
cat > src/Core/Domain/ValueObject/Siren.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class Siren
{
    public function __construct(
        private string $value
    ) {
        $this->assertIsValid($value);
    }

    private function assertIsValid(string $value): void
    {
        if (!preg_match('/^[0-9]{9}$/', $value)) {
            throw new \InvalidArgumentException(sprintf('Invalid SIREN "%s"', $value));
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
PHP

cat > src/Core/Domain/ValueObject/EmailAddress.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class EmailAddress
{
    public function __construct(
        private string $value
    ) {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException(sprintf('Invalid email "%s"', $value));
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
PHP

cat > src/Core/Domain/ValueObject/PhoneNumber.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class PhoneNumber
{
    public function __construct(
        private string $value
    ) {
        if (!preg_match('/^[+0-9][0-9\s]{5,}$/', $value)) {
            throw new \InvalidArgumentException(sprintf('Invalid phone number "%s"', $value));
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
PHP

cat > src/Core/Domain/ValueObject/Address.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class Address
{
    public function __construct(
        private string $value
    ) {
        if (trim($value) === '') {
            throw new \InvalidArgumentException('Address cannot be empty');
        }
    }

    public function value(): string
    {
        return $this->value;
    }
}
PHP

cat > src/Core/Domain/ValueObject/ShareCapital.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain\ValueObject;

final class ShareCapital
{
    public function __construct(
        private int|float $value
    ) {
        if ($value < 0) {
            throw new \InvalidArgumentException('Share capital cannot be negative');
        }
    }

    public function value(): int|float
    {
        return $this->value;
    }
}
PHP

#####################
# Domain Company
#####################
cat > src/Core/Domain/Company.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain;

use App\Core\Domain\ValueObject\Address;
use App\Core\Domain\ValueObject\EmailAddress;
use App\Core\Domain\ValueObject\PhoneNumber;
use App\Core\Domain\ValueObject\ShareCapital;
use App\Core\Domain\ValueObject\Siren;

final class Company
{
    public function __construct(
        private Siren $siren,
        private PhoneNumber $phoneNumber,
        private Address $address,
        private EmailAddress $email,
        private ShareCapital $shareCapital
    ) {
    }

    public function siren(): Siren
    {
        return $this->siren;
    }

    public function phoneNumber(): PhoneNumber
    {
        return $this->phoneNumber;
    }

    public function address(): Address
    {
        return $this->address;
    }

    public function email(): EmailAddress
    {
        return $this->email;
    }

    public function shareCapital(): ShareCapital
    {
        return $this->shareCapital;
    }

    public function toArray(): array
    {
        return [
            'siren'   => $this->siren->value(),
            'phone'   => $this->phoneNumber->value(),
            'address' => $this->address->value(),
            'email'   => $this->email->value(),
            'capital' => $this->shareCapital->value(),
        ];
    }
}
PHP

#####################
# Validation
#####################
cat > src/Core/Domain/Validation/CompanyValidationError.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain\Validation;

final class CompanyValidationError
{
    /**
     * @param string[] $fields
     */
    public function __construct(
        private string $message,
        private array $fields
    ) {
    }

    public function message(): string
    {
        return $this->message;
    }

    /**
     * @return string[]
     */
    public function fields(): array
    {
        return $this->fields;
    }
}
PHP

cat > src/Core/Domain/Validation/CompanyValidator.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Core\Domain\Validation;

use App\Core\Domain\Company;
use App\Core\Domain\ValueObject\Address;
use App\Core\Domain\ValueObject\EmailAddress;
use App\Core\Domain\ValueObject\PhoneNumber;
use App\Core\Domain\ValueObject\ShareCapital;
use App\Core\Domain\ValueObject\Siren;

final class CompanyValidator
{
    /**
     * @param array<string, mixed> $rawData
     *
     * @return array{
     *   company: Company|null,
     *   errors: CompanyValidationError[]
     * }
     */
    public function validate(array $rawData): array
    {
        $errors = [];

        $siren   = $rawData['siren']   ?? null;
        $phone   = $rawData['phone']   ?? null;
        $address = $rawData['address'] ?? null;
        $email   = $rawData['email']   ?? null;
        $capital = $rawData['capital'] ?? null;

        $company = null;

        try {
            $company = new Company(
                new Siren((string) $siren),
                new PhoneNumber((string) $phone),
                new Address((string) $address),
                new EmailAddress((string) $email),
                new ShareCapital((int) $capital)
            );
        } catch (\InvalidArgumentException $exception) {
            $invalidFields = [];

            if (!$this->isValidSiren($siren)) {
                $invalidFields[] = 'siren';
            }
            if (!$this->isValidPhone($phone)) {
                $invalidFields[] = 'phone';
            }
            if (!$this->isValidAddress($address)) {
                $invalidFields[] = 'address';
            }
            if (!$this->isValidEmail($email)) {
                $invalidFields[] = 'email';
            }
            if (!$this->isValidCapital($capital)) {
                $invalidFields[] = 'capital';
            }

            $errors[] = new CompanyValidationError(
                $exception->getMessage(),
                $invalidFields
            );
        }

        return [
            'company' => $company,
            'errors'  => $errors,
        ];
    }

    private function isValidSiren(mixed $value): bool
    {
        return is_string($value) && preg_match('/^[0-9]{9}$/', $value) === 1;
    }

    private function isValidPhone(mixed $value): bool
    {
        return is_string($value) && preg_match('/^[+0-9][0-9\s]{5,}$/', $value) === 1;
    }

    private function isValidAddress(mixed $value): bool
    {
        return is_string($value) && trim($value) !== '';
    }

    private function isValidEmail(mixed $value): bool
    {
        return is_string($value) && filter_var($value, FILTER_VALIDATE_EMAIL) !== false;
    }

    private function isValidCapital(mixed $value): bool
    {
        return is_numeric($value) && (int) $value >= 0;
    }
}
PHP

#####################
# Infrastructure
#####################
cat > src/Infrastructure/FileSystem/JsonCompanyFileReader.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Infrastructure\FileSystem;

use App\Core\Application\Ports\CompanyFileReaderInterface;

final class JsonCompanyFileReader implements CompanyFileReaderInterface
{
    public function read(string $filePath): array
    {
        if (!is_file($filePath)) {
            throw new \RuntimeException(sprintf('File "%s" does not exist', $filePath));
        }

        $content = file_get_contents($filePath);
        if ($content === false) {
            throw new \RuntimeException(sprintf('Cannot read file "%s"', $filePath));
        }

        $data = json_decode($content, true, 512, JSON_THROW_ON_ERROR);

        if (!is_array($data)) {
            throw new \RuntimeException('Invalid JSON structure: expected array of companies');
        }

        return $data;
    }
}
PHP

cat > src/Infrastructure/Logger/JsonFileCompanyValidationLogger.php <<'PHP'
<?php

declare(strict_types=1);

namespace App\Infrastructure\Logger;

use App.Core\Application\Ports\CompanyValidationLoggerInterface;
use App\Core\Domain\Company;
use App\Core\Domain\Validation\CompanyValidationError;

final class JsonFileCompanyValidationLogger implements CompanyValidationLoggerInterface
{
    public function __construct(
        private string $logDir = __DIR__ . '/../../../var/log'
    ) {
    }

    public function logFileResult(
        string $filePath,
        array $validCompanies,
        array $invalidCompanies
    ): void {
        if (!is_dir($this->logDir)) {
            mkdir($this->logDir, 0777, true);
        }

        $baseName = pathinfo($filePath, PATHINFO_FILENAME);

        $successFile = sprintf('%s/%s.success.json', $this->logDir, $baseName);
        $errorFile   = sprintf('%s/%s.errors.json', $this->logDir, $baseName);

        $successPayload = array_map(
            static fn (Company $company): array => $company->toArray(),
            $validCompanies
        );

        $errorsPayload = array_map(
            static function (array $row): array {
                /** @var array<string, mixed> $raw */
                $raw = $row['raw'];

                /** @var CompanyValidationError[] $errors */
                $errors = $row['errors'];

                return [
                    'raw'    => $raw,
                    'errors' => array_map(
                        static fn (CompanyValidationError $error): array => [
                            'message' => $error->message(),
                            'fields'  => $error->fields(),
                        ],
                        $errors
                    ),
                ];
            },
            $invalidCompanies
        );

        file_put_contents(
            $successFile,
            json_encode($successPayload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
        );

        file_put_contents(
            $errorFile,
            json_encode($errorsPayload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)
        );
    }
}
PHP

#####################
# Docker
#####################
cat > docker/php/Dockerfile <<'DOCKER'
FROM php:8.3-cli

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    unzip \
 && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY . /app

RUN composer install --no-interaction --no-progress

CMD ["php", "bin/console"]
DOCKER

cat > docker-compose.yml <<'YAML'
version: "3.9"

services:
  company-json-validator:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    volumes:
      - ./:/app
    working_dir: /app
    command: ["php", "bin/console", "app:validate:companies", "data/input"]
YAML

#####################
# Sample JSON
#####################
cat > data/input/entreprises_01.json <<'JSON'
[
  {
    "siren": "123456789",
    "phone": "+33123456789",
    "address": "1 rue de la Paix, 75000 Paris",
    "email": "contact@exemple.fr",
    "capital": 10000
  },
  {
    "siren": "ABC",
    "phone": "12",
    "address": "",
    "email": "not-an-email",
    "capital": -42
  }
]
JSON

echo "✅ Arborescence et fichiers générés."
