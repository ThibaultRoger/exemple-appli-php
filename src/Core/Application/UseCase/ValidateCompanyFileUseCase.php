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
