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
