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
