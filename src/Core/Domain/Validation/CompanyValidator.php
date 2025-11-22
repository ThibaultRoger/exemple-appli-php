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
